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

until psql -U "$POSTGRES_USER" -d postgres -c '\l'; do
	echo "Waiting for PostgreSQL to start..."
	sleep 2
done

until psql -U "$POSTGRES_USER" -d template1 -c 'SELECT 1'; do
	echo "Waiting for PostgreSQL to start..."
	sleep 2
done

if [ ! -f /var/lib/postgresql/18/docker/.extensions_installed ]; then
	psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname postgres -f /install_extensions.sql

	touch /var/lib/postgresql/18/docker/.extensions_installed
fi

wait "$PG_PID"
