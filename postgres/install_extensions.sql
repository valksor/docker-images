\c postgres;
CREATE SCHEMA IF NOT EXISTS public;

CREATE EXTENSION IF NOT EXISTS dblink WITH SCHEMA public;

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
GRANT USAGE ON SCHEMA public TO PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO PUBLIC;

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;
GRANT EXECUTE ON FUNCTION public.unaccent(text) TO PUBLIC;

CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;

CREATE EXTENSION IF NOT EXISTS timescaledb;

CREATE EXTENSION IF NOT EXISTS vectorscale WITH SCHEMA public;

CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

ALTER DATABASE template1 SET search_path TO public, "$POSTGRES_USER", pg_catalog;

\c template1;
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
GRANT USAGE ON SCHEMA public TO PUBLIC;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO PUBLIC;
CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;
GRANT EXECUTE ON FUNCTION public.unaccent(text) TO PUBLIC;
CREATE EXTENSION IF NOT EXISTS vector WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS timescaledb;
CREATE EXTENSION IF NOT EXISTS vectorscale WITH SCHEMA public;
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

\c postgres;
SET search_path TO public, "$POSTGRES_USER", pg_catalog;

DO $$
    DECLARE
        db_name text;
    BEGIN
        FOR db_name IN SELECT datname FROM pg_database WHERE NOT datistemplate AND datname NOT IN ('postgres', 'template0', 'template1')
            LOOP
                PERFORM dblink_exec('dbname=' || quote_literal(db_name),
                    'SET search_path = public;
                    CREATE EXTENSION IF NOT EXISTS pgcrypto;
                    GRANT USAGE ON SCHEMA public TO PUBLIC;
                    GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO PUBLIC;
                    CREATE EXTENSION IF NOT EXISTS unaccent;
                    GRANT EXECUTE ON FUNCTION public.unaccent(text) TO PUBLIC;
                    CREATE EXTENSION IF NOT EXISTS vector;
                    CREATE EXTENSION IF NOT EXISTS timescaledb;
                    CREATE EXTENSION IF NOT EXISTS vectorscale;
                    CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
                    SET search_path TO public, "' || current_user || '", pg_catalog;');
            END LOOP;
END $$;
