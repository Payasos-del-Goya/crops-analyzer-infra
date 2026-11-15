#!/bin/bash
# Buckets de InfluxDB (los mismos y con la misma retención que en la Raspberry).
# Lo ejecuta la imagen oficial influxdb:2 una sola vez, tras el setup inicial (el bucket c001_campo ya lo crea el setup).
set -euo pipefail
crear() { influx bucket create --org "$DOCKER_INFLUXDB_INIT_ORG" --name "$1" --retention "$2" >/dev/null; echo "bucket $1 ($2)"; }
crear c001_estado 90d
crear c001_campo_diario 0
crear c001_nasa 0
for c in c002 c003 c004; do
  crear "${c}_campo" 730d
  crear "${c}_estado" 90d
done
crear icinga 30d
crear mqtt 30d
