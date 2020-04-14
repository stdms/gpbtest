#!/bin/bash

set -e

psql -v --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE gpbtest ENCODING 'utf-8';
    CREATE ROLE gpbtest LOGIN PASSWORD 'test';
EOSQL

psql --username "$POSTGRES_USER" $POSTGRES_DB < /scripts/schema.sql
