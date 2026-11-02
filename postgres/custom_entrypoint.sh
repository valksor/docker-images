#!/usr/bin/env bash

set -eux

# The official entrypoint only defaults POSTGRES_USER inside its own (backgrounded)
# process, so this parent shell would hit an unbound variable under `set -u` when the
# caller doesn't pass POSTGRES_USER. Default it here so every psql below is safe.
: "${POSTGRES_USER:=postgres}"
export POSTGRES_USER

# Marker lives in the data dir so it persists across restarts; derive it from PGDATA
# rather than hardcoding a major-version path.
EXTENSIONS_MARKER="${PGDATA:-/var/lib/postgresql/18/docker}/.extensions_installed"

PG_PID=
cleanup() {
	[ -n "$PG_PID" ] || return 0
	# SIGINT = fast shutdown: disconnects clients and writes a clean shutdown checkpoint.
	# SIGTERM is "smart" shutdown, which waits for idle pooler connections until the
	# orchestrator's grace period SIGKILLs postgres and tears the checkpoint.
	kill -INT "$PG_PID" 2>/dev/null || true
	wait "$PG_PID" 2>/dev/null || true
}
trap cleanup SIGTERM SIGINT

# Configure shared_preload_libraries for extensions that need startup loading.
# timescaledb must be first; pg_cron, pg_partman_bgw, pgaudit, age, pg_squeeze, pg_stat_statements are order-independent.
export POSTGRES_INITDB_ARGS="${POSTGRES_INITDB_ARGS:-} --set shared_preload_libraries='timescaledb,pg_cron,pg_partman_bgw,pgaudit,age,pg_squeeze,pg_stat_statements'"

# max_worker_processes default sized for the bundled extension set: timescaledb
# launcher + one scheduler per database that enables timescaledb, pg_cron launcher,
# pg_partman_bgw, pg_squeeze, logical replication launcher, plus parallel query
# budget. The default 8 starves once ~3+ databases use timescaledb. pgaudit.log
# defaults to none, so pgaudit would log nothing; role audits privilege and role
# changes. ddl is left out: migrations, test databases and the extension sync
# below flood the shared log stream with it. Consumers can
# override any flag via compose `command:` — later -c flags win in postgres arg
# processing, so "$@" below supersedes these defaults.
docker-entrypoint.sh postgres \
	-c shared_preload_libraries='timescaledb,pg_cron,pg_partman_bgw,pgaudit,age,pg_squeeze,pg_stat_statements' \
	-c pgaudit.log='role' \
	-c cron.database_name="${POSTGRES_DB:-postgres}" \
	-c max_worker_processes=32 \
	-c timescaledb.max_background_workers=16 \
	"$@" &
PG_PID=$!

MAX_RETRIES=120
RETRY=0
# On first boot the official entrypoint runs a temporary socket-only server for initdb, which
# answers psql over the socket and then shuts down. Only the final server listens on TCP, so
# require that before installing extensions.
until pg_isready -h 127.0.0.1 -p "${PGPORT:-5432}" -U "$POSTGRES_USER" -d postgres -q && psql -U "$POSTGRES_USER" -d postgres -c '\l'; do
	if ! kill -0 "$PG_PID" 2>/dev/null; then
		echo "ERROR: PostgreSQL process has died. Check logs above for details."
		exit 1
	fi
	RETRY=$((RETRY + 1))
	if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
		echo "ERROR: PostgreSQL failed to start after $MAX_RETRIES attempts."
		exit 1
	fi
	echo "Waiting for PostgreSQL to start... (attempt $RETRY/$MAX_RETRIES)"
	sleep 2
done

until psql -U "$POSTGRES_USER" -d template1 -c 'SELECT 1'; do
	if ! kill -0 "$PG_PID" 2>/dev/null; then
		echo "ERROR: PostgreSQL process has died."
		exit 1
	fi
	echo "Waiting for template1..."
	sleep 2
done

if [ ! -f "$EXTENSIONS_MARKER" ]; then
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -f /install_extensions.sql

	touch "$EXTENSIONS_MARKER"
fi

# Sync installed extensions to the binary versions shipped in this image. Runs
# every boot so image rebuilds (e.g. timescaledb 2.25 -> 2.26) don't leave
# existing databases stuck on the old SQL-layer version. Idempotent: ALTER
# EXTENSION UPDATE is a no-op when already current.
#
# Each ALTER runs in its own psql -X session so the ALTER is the very first
# statement the backend sees. This is required by timescaledb's update guard,
# which refuses the update if its SQL module has already been loaded in the
# session (which happens during psql's default startup queries, even without a
# .psqlrc). See the HINT in "extension cannot be updated after the old version
# has already been loaded": 'Make sure to pass the "-X" flag to psql.'
#
# When the update fails for any reason, the extension is dropped and recreated
# as a fallback, but only when it is listed in STATELESS_EXTENSIONS. The
# recreate resets grants and comments on the extension's member objects, so
# only extensions where that is acceptable can be on the list; DROP EXTENSION
# also removes member tables (for example pg_cron's cron.job), so stateful
# extensions must never be added.
STATELESS_EXTENSIONS="plpgsql_check"

echo "Syncing installed extensions to image binary versions..."
while IFS= read -r db <&3; do
	for ext in $(PGDATABASE="$db" psql -X -U "$POSTGRES_USER" -tAc \
		"select extname from pg_extension where extname <> 'plpgsql' order by extname"); do
		if PGDATABASE="$db" psql -X -U "$POSTGRES_USER" -v ON_ERROR_STOP=0 \
			-c "ALTER EXTENSION \"$ext\" UPDATE;"; then
			continue
		fi
		case " $STATELESS_EXTENSIONS " in
		*" $ext "*)
			# The update can fail for any reason (e.g. plpgsql_check 2.8 -> 2.10
			# has no update path). Recreate inside a single transaction: without
			# CASCADE the DROP fails if anything outside the extension depends
			# on its members, and the transaction rolls back.
			# %I quotes the identifier: a database owner can rename the schema.
			schema=$(PGDATABASE="$db" psql -X -U "$POSTGRES_USER" -tAc \
				"select format('%I', n.nspname) from pg_extension e join pg_namespace n on n.oid = e.extnamespace where e.extname = '$ext'") || {
				echo "WARNING: recreate of extension '$ext' in database '$db' failed"
				continue
			}
			if PGDATABASE="$db" psql -X -U "$POSTGRES_USER" -v ON_ERROR_STOP=1 -1 \
				-c "DROP EXTENSION \"$ext\";" \
				-c "CREATE EXTENSION \"$ext\" SCHEMA $schema;"; then
				echo "Recreated extension '$ext' in database '$db' (update failed)"
			else
				echo "WARNING: recreate of extension '$ext' in database '$db' failed (objects may depend on it)"
			fi
			;;
		*)
			echo "WARNING: update of extension '$ext' in database '$db' failed"
			;;
		esac
	done
done 3< <(psql -X -U "$POSTGRES_USER" -d postgres -tAc \
	"select datname from pg_database where datallowconn and datname <> 'template0' order by datname")

wait "$PG_PID"
