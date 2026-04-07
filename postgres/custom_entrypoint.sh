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

docker-entrypoint.sh postgres \
	-c shared_preload_libraries='timescaledb,pg_cron,pg_partman_bgw,pgaudit,age,pg_squeeze' \
	-c cron.database_name="${POSTGRES_DB:-postgres}" &
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

wait "$PG_PID"
