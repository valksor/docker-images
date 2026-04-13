#!/usr/bin/env bash

set -eux

cleanup() {
	kill -TERM "$PG_PID" 2>/dev/null || true
	wait "$PG_PID"
}
trap cleanup SIGTERM SIGINT

# Configure shared_preload_libraries for extensions that need startup loading.
# timescaledb must be first; pg_cron, pg_partman_bgw, pgaudit, age, pg_squeeze are order-independent.
export POSTGRES_INITDB_ARGS="${POSTGRES_INITDB_ARGS:-} --set shared_preload_libraries='timescaledb,pg_cron,pg_partman_bgw,pgaudit,age,pg_squeeze'"

# max_worker_processes default sized for the bundled extension set: timescaledb
# launcher + one scheduler per database that enables timescaledb, pg_cron launcher,
# pg_partman_bgw, pg_squeeze, logical replication launcher, plus parallel query
# budget. The default 8 starves once ~3+ databases use timescaledb. Consumers can
# override any flag via compose `command:` — later -c flags win in postgres arg
# processing, so "$@" below supersedes these defaults.
docker-entrypoint.sh postgres \
	-c shared_preload_libraries='timescaledb,pg_cron,pg_partman_bgw,pgaudit,age,pg_squeeze' \
	-c cron.database_name="${POSTGRES_DB:-postgres}" \
	-c max_worker_processes=32 \
	-c timescaledb.max_background_workers=16 \
	"$@" &
PG_PID=$!

MAX_RETRIES=30
RETRY=0
until psql -U "$POSTGRES_USER" -d postgres -c '\l'; do
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

if [ ! -f /var/lib/postgresql/data/.extensions_installed ]; then
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -f /install_extensions.sql

	touch /var/lib/postgresql/data/.extensions_installed
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
echo "Syncing installed extensions to image binary versions..."
for db in $(psql -X -U "$POSTGRES_USER" -d postgres -tAc \
	"select datname from pg_database where datallowconn and datname <> 'template0' order by datname"); do
	for ext in $(psql -X -U "$POSTGRES_USER" -d "$db" -tAc \
		"select extname from pg_extension where extname <> 'plpgsql' order by extname"); do
		psql -X -U "$POSTGRES_USER" -d "$db" -v ON_ERROR_STOP=0 \
			-c "ALTER EXTENSION \"$ext\" UPDATE;" \
			|| echo "WARNING: update of extension '$ext' in database '$db' failed"
	done
done

wait "$PG_PID"
