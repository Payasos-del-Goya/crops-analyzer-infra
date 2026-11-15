# crops-analyzer-infra

Infraestructura de **plot-advisor**: cómo se despliega todo en contenedores.

Hay dos maneras de usarlo:

| | Qué levanta | Dónde |
|---|---|---|
| [`compose.yaml`](compose.yaml) | **Toda la infraestructura desde cero**: PostgreSQL, InfluxDB, Mosquitto, Telegraf, Grafana, backend y frontend | Cualquier máquina con Docker (otra Raspberry, un servidor, un portátil) |
| [`raspberry/`](raspberry/README.md) | **Solo backend y frontend**, junto a lo que la Raspberry `fieldshift-gw` ya tiene instalado, cada uno como servicio de systemd y en `http://plotadvisor.local` | La Raspberry de la demo |

El código de la aplicación no está aquí: las imágenes se construyen a partir de los repos
[crops-analyzer-backend](https://github.com/Payasos-del-Goya/crops-analyzer-backend) y
[crops-analyzer-frontend](https://github.com/Payasos-del-Goya/crops-analyzer-frontend), que tienen que estar
como carpetas hermanas de esta (así quedan al clonar [plot-advisor](https://github.com/Payasos-del-Goya/plot-advisor)
con sus submódulos):

```
plot-advisor/
├── crops-analyzer-backend/
├── crops-analyzer-frontend/
└── crops-analyzer-infra/     <- este repo
```

## Infraestructura completa

```bash
cd crops-analyzer-infra
docker compose up -d --build
```

| Servicio | Dirección | Notas |
|---|---|---|
| Panel | http://localhost | `cliente1`…`cliente4`, contraseña = usuario |
| Grafana | http://localhost:3000 | `admin` / `plotadvisor-grafana`; dashboards de campo, MQTT e Icinga |
| MQTT (balizas) | `localhost:1883` | usuario y clave del firmware (`puente/config.h` de crops-analyzer-module) |
| InfluxDB | http://localhost:8086 | `admin` / `plotadvisor-influx-admin`, org `fieldshift` |

Al arrancar por primera vez:

- **PostgreSQL** se crea con el esquema y los datos de referencia de la Raspberry (`config/postgres/`): los 93
  cultivos, los clientes c001–c004 con sus balizas y los usuarios de demo.
- **InfluxDB** crea los buckets (`config/influxdb/buckets.sh`), vacíos: los datos empiezan a llegar cuando las balizas
  publiquen en este Mosquitto (o con los generadores de las fincas simuladas).
- **Mosquitto** genera usuarios y permisos a partir de las variables del compose (`config/mosquitto/entrypoint.sh`).

Para empezar de cero: `docker compose down -v` (borra también los datos).

Las claves son de demo y van en el propio `compose.yaml` (bloque `x-claves`), igual que en el resto del proyecto.
Para otra instalación, cambiarlas ahí.

**Fuera del compose:** Icinga 2 (vigila la propia máquina: temperatura, servicios, WiFi) y la WiFi de las balizas
(`GatewayPA`), que van instaladas directamente en la Raspberry.

## Estructura

```
compose.yaml                 infraestructura completa
docker/backend/Dockerfile    imagen del backend (Python 3.13, uvicorn)
docker/frontend/Dockerfile   imagen del frontend (Node 22, next build + next start)
config/postgres/             roles, esquema y datos iniciales
config/influxdb/             buckets
config/mosquitto/            broker con usuario obligatorio
config/telegraf/             MQTT -> InfluxDB (datos de las balizas y métricas del broker)
config/grafana/              orígenes de datos y dashboards
raspberry/                   despliegue en la Raspberry fieldshift-gw
```
