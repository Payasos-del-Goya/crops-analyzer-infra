#!/bin/bash
# Usuarios de la base de datos (como en la Raspberry):
#   fieldshift_app      dueño de las tablas; lo usa el backend.
#   fieldshift_lectura  solo lectura (Grafana); no ve la tabla usuarios.
set -euo pipefail
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
  -v app_pw="$POSTGRES_APP_PASSWORD" -v lectura_pw="$POSTGRES_READER_PASSWORD" <<'SQL'
CREATE ROLE fieldshift_app LOGIN PASSWORD :'app_pw';
CREATE ROLE fieldshift_lectura LOGIN PASSWORD :'lectura_pw';
GRANT CONNECT ON DATABASE fieldshift TO fieldshift_app, fieldshift_lectura;
GRANT USAGE, CREATE ON SCHEMA public TO fieldshift_app;
GRANT USAGE ON SCHEMA public TO fieldshift_lectura;
SQL
