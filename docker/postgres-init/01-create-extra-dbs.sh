#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE stopanddance_production_cache OWNER $POSTGRES_USER;
    CREATE DATABASE stopanddance_production_queue OWNER $POSTGRES_USER;
    CREATE DATABASE stopanddance_production_cable OWNER $POSTGRES_USER;
EOSQL
