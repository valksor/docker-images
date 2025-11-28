#!/usr/bin/env bash

set -eux

docker-entrypoint.sh postgres &

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

wait
