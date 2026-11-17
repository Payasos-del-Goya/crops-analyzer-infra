# crops-analyzer-infra

Infraestructura de **plot-advisor**: dónde se guardan, se vigilan y se sirven los datos de las balizas. Todo se
despliega con Docker.

## Recorrido de los datos

```text
Balizas ESP32 --(malla painlessMesh)--> Puente ESP32 --(WiFi GatewayPA)--> Raspberry Pi fieldshift-gw

En la Raspberry:
  Mosquitto :1883 --> Telegraf --> InfluxDB :8086 --> Grafana :3000
                                       |
  PostgreSQL ------------------> Backend (FastAPI) --> Frontend (Next.js) --> http://plotadvisor.local
```

Las balizas no hablan con la Raspberry: mandan sus lecturas por la malla al puente, y el puente las publica por MQTT.
El formato exacto de cada mensaje está en
[`FORMATO_DATOS.md`](https://github.com/Payasos-del-Goya/crops-analyzer-module/blob/main/FORMATO_DATOS.md) de
crops-analyzer-module.

## Formas de desplegarlo

| | Qué levanta | Dónde |
|---|---|---|
| [`compose.yaml`](compose.yaml) | **Toda la infraestructura desde cero**: PostgreSQL, InfluxDB, Mosquitto, Telegraf, Grafana, backend y frontend | Cualquier máquina con Docker (otra Raspberry, un servidor, un portátil) |
| [`raspberry/`](raspberry/README.md) | **Solo backend y frontend**, junto a lo que la Raspberry `fieldshift-gw` ya tiene instalado, cada uno como servicio de systemd y en `http://plotadvisor.local` | La Raspberry de la demo |

El código de la aplicación no está aquí: las imágenes se construyen a partir de los repos
[crops-analyzer-backend](https://github.com/Payasos-del-Goya/crops-analyzer-backend) y
[crops-analyzer-frontend](https://github.com/Payasos-del-Goya/crops-analyzer-frontend), que tienen que estar
como carpetas hermanas de esta. Así quedan al clonar [plot-advisor](https://github.com/Payasos-del-Goya/plot-advisor)
con sus submódulos:

```text
plot-advisor/
├── crops-analyzer-backend/
├── crops-analyzer-frontend/
├── crops-analyzer-infra/     <- este repo
└── crops-analyzer-module/
```

### Infraestructura completa

```bash
git clone --recurse-submodules https://github.com/Payasos-del-Goya/plot-advisor
cd plot-advisor/crops-analyzer-infra
docker compose up -d --build
```

| Servicio | Dirección | Acceso |
|---|---|---|
| Panel | http://localhost | `cliente1`…`cliente4`, contraseña = usuario |
| Grafana | http://localhost:3000 | `admin` / `plotadvisor-grafana` |
| MQTT (balizas) | `localhost:1883` | usuario y clave del firmware (`puente/config.h` de crops-analyzer-module) |
| InfluxDB | http://localhost:8086 | `admin` / `plotadvisor-influx-admin`, org `fieldshift` |

Al arrancar por primera vez:

- **PostgreSQL** se crea con el esquema y los datos de referencia de la Raspberry (`config/postgres/`): los 93
  cultivos, los clientes c001–c004 con sus balizas y los usuarios de demo.
- **InfluxDB** crea los buckets (`config/influxdb/buckets.sh`) vacíos: los datos empiezan a llegar cuando las
  balizas publiquen en este Mosquitto (o con los generadores de las fincas simuladas).
- **Mosquitto** genera usuarios y permisos a partir de las variables del compose (`config/mosquitto/entrypoint.sh`).

Para empezar de cero: `docker compose down -v` (borra también los datos).

### Raspberry `fieldshift-gw`

En la Raspberry de la demo, PostgreSQL, InfluxDB, Mosquitto, Telegraf, Grafana e Icinga 2 van instalados
directamente. Docker solo añade el backend y el frontend, cada uno como servicio de systemd, con Apache delante y el
nombre `plotadvisor.local` anunciado por mDNS. Los pasos de instalación están en
[`raspberry/README.md`](raspberry/README.md).

*Docker tiene que estar configurado **antes** de instalarlo con `"iptables": false` en `/etc/docker/daemon.json`.
Si no, Docker reescribe el cortafuegos y los dispositivos conectados a la WiFi `GatewayPA` se quedan sin Internet.*

## Servicios

### Mosquitto

Broker MQTT de las balizas, en el puerto `1883`. No admite conexiones anónimas: el usuario y la clave se generan al
arrancar a partir de las variables del compose ([`config/mosquitto/entrypoint.sh`](config/mosquitto/entrypoint.sh)).

| Usuario | Permisos |
|---|---|
| `plot-advisor` (el puente) | Leer y escribir en todos los topics |
| `telegraf` | Solo leer: los datos y las métricas del broker (`$SYS/#`) |

### Telegraf

Pasa los mensajes de MQTT a InfluxDB sin traducciones: cada JSON del puente es un punto.

| Topic MQTT | Measurement | Bucket | Configuración |
|---|---|---|---|
| `plot-advisor/c001/<dispositivo>/suelo` | `suelo` | `c001_campo` | [`campo.conf`](config/telegraf/campo.conf) |
| `plot-advisor/c001/<dispositivo>/atmosfera` | `atmosfera` | `c001_campo` | [`campo.conf`](config/telegraf/campo.conf) |
| `plot-advisor/c001/<dispositivo>/estado` | `dispositivo` | `c001_estado` | [`campo.conf`](config/telegraf/campo.conf) |
| `$SYS/#` y todos los topics de las balizas | `mosquitto`, `mqtt_topic` | `mqtt` | [`mqtt.conf`](config/telegraf/mqtt.conf) |

También acepta el prefijo antiguo `fieldshift/` en lugar de `plot-advisor/`.

### InfluxDB

Guarda las series temporales. Cada cliente tiene sus propios buckets, para que los datos de una finca no se mezclen
con los de otra.

| Bucket | Qué guarda | Retención |
|---|---|---|
| `c001_campo` … `c004_campo` | Lecturas de suelo y atmósfera | 730 días |
| `c001_estado` … `c004_estado` | Estado de cada placa: batería, RSSI, memoria, reinicios | 90 días |
| `icinga` | Resultados de los checks de Icinga 2 | 30 días |
| `mqtt` | Métricas del broker y mensajes por topic | 30 días |
| `c001_campo_diario`, `c001_nasa` | Existen en la Raspberry; nada de este repo escribe en ellos todavía | Sin límite |

### PostgreSQL

Guarda lo que no es una serie temporal: los clientes, la posición de cada baliza y los datos de los cultivos. Se
carga desde [`config/postgres/`](config/postgres/).

| Tabla | Contenido |
|---|---|
| `clientes` | `c001` demo, `c002` Bajo Cinca, `c003` Slaney, `c004` Romerike |
| `balizas` | Posición, cliente, zona y textura del suelo de cada baliza |
| `cultivos` | 93 cultivos con sus parámetros de FAO-56 (coeficientes, temperaturas, pH, salinidad…) |
| `cultivos_leyenda` | Explicación de cada columna de `cultivos` |
| `usuarios` | Usuarios del panel, uno por cliente |

Hay dos roles: `fieldshift_app` (el backend, lee y escribe) y `fieldshift_lectura` (Grafana, solo lee).

### Grafana

Se arranca con los orígenes de datos (InfluxDB y PostgreSQL) y tres dashboards ya cargados
([`config/grafana/`](config/grafana/)):

| Dashboard | Qué enseña |
|---|---|
| `fieldshift · campo` | Últimas lecturas y evolución de temperatura, humedad, luz, lluvia, pH y conductividad |
| `fieldshift · MQTT` | Clientes conectados, mensajes por minuto y mensajes de cada baliza |
| `fieldshift · monitorización (Icinga)` | Estado de los checks, balizas sin datos, RSSI de la malla, memoria de las placas y temperatura, carga y memoria de la Raspberry |

### Backend y frontend

Se construyen a partir de sus repos con los Dockerfiles de [`docker/`](docker/):

- **Backend:** Python 3.13 y uvicorn, en el puerto `8000`. Guarda el clima de Meteomatics en un volumen para que
  sobreviva a los reinicios.
- **Frontend:** Node 22 con `next build` y `next start`. La dirección del backend se fija al compilar, porque Next
  la necesita para redirigir `/api/*`.

Los dos corren con un usuario sin privilegios.

### Icinga 2 (fuera del compose)

Va instalado directamente en la Raspberry y su configuración no está en este repo. Vigila la propia Raspberry
(temperatura, servicios, WiFi) y cada baliza, guarda los resultados en el bucket `icinga` y avisa cuando algo cae. El
panel usa ese estado para marcar en rojo las balizas caídas.

## Estudio de almacenamiento

El cálculo combina datos de tres fuentes:

1. **Firmware:** periodos de envío de
   [`comun.h`](https://github.com/Payasos-del-Goya/crops-analyzer-module/blob/main/nodo_sensor/comun.h) y campos
   de cada mensaje de
   [`FORMATO_DATOS.md`](https://github.com/Payasos-del-Goya/crops-analyzer-module/blob/main/FORMATO_DATOS.md).
2. **Retención:** [`config/influxdb/buckets.sh`](config/influxdb/buckets.sh).
3. **InfluxDB:** *Hardware sizing guidelines*, apartado de bytes y compresión.
   [Documentación oficial de InfluxData](https://docs.influxdata.com/influxdb/v1/guides/hardware_sizing/).

### 1. Datos que proporciona el firmware

```text
Suelo:     1 mensaje cada 30 s, hasta 3 valores (humedad_vol, conductividad, temperatura)
Atmósfera: 1 mensaje cada 30 s, hasta 7 valores (temp_aire, hr, temp_helada, temp_cubierta,
           lluvia_mm, hoja_mojada_min, luz_lux)
Estado:    1 mensaje cada 60 s, hasta 7 valores numéricos (bateria_v, rssi, seq, sensores_ok,
           heap_libre, heap_bloque, uptime_s)
```

Se usa el número **máximo** de campos de cada mensaje para obtener una estimación conservadora. Un MiFlora, por
ejemplo, manda menos: humedad y conductividad en suelo, y temperatura y luz en atmósfera. Se supone una sola sonda
de suelo por baliza; cada sonda o profundidad más añade su propio mensaje.

### 2. Datos de InfluxDB

La guía de InfluxData indica que cada valor numérico ocupa **unos 3 bytes** una vez comprimido. Los nombres de los
measurements, los tags y los campos se guardan una sola vez, no en cada punto.

### 3. Cálculo

Valores al día de una baliza:

```text
campo  = (86400 / 30) * (3 + 7) = 28800 valores/día
estado = (86400 / 60) * 7       = 10080 valores/día
```

Con la retención de cada bucket:

```text
campo  = 28800 * 730 días * 3 B = 63,1 MB por baliza
estado = 10080 *  90 días * 3 B =  2,7 MB por baliza
```

### 4. Resultado para la finca demo

Para la finca `c001`, con 4 balizas y un puente (el puente solo manda estado):

```text
campo  = 4 * 63,1 MB = 252,3 MB
estado = 5 *  2,7 MB =  13,6 MB
total                ≈ 266 MB
```

| Balizas | Espacio ocupado en InfluxDB |
|---:|---:|
| 4 | 0,27 GB |
| 20 | 1,3 GB |
| 50 | 3,3 GB |
| 100 | 6,6 GB |

Con la tarjeta de 64 GB del kit de la Raspberry, la finca demo ocupa en torno a un **0,4 %**, y queda sitio para
cientos de balizas.

El resultado es una **estimación teórica**, no una medición. No incluye los índices de InfluxDB, el WAL, el campo
de texto `gateway` del estado, los buckets `mqtt` e `icinga`, PostgreSQL, Grafana, las imágenes de Docker ni el sistema. Para validarla hay que medir el
directorio de datos de InfluxDB tras unas semanas de funcionamiento (`sudo du -sh /var/lib/influxdb` en la
Raspberry, `docker system df -v` con el compose).

## Estudio de precio de la infraestructura

Este es un presupuesto orientativo de la **parte de la Raspberry**. Los precios son los del estudio económico de
[plot-advisor](https://github.com/Payasos-del-Goya/plot-advisor#estudio-económico-de-una-implementación-mínima-con-3-nodos),
consultados el 15/11/2026. No incluyen envío ni posibles cupones.

| Componente | Cantidad | Precio orientativo | Fuente |
|---|---:|---:|---|
| Raspberry Pi 5 Starter Kit (4 GB, 64 GB, fuente de 27 W) | 1 | 189,99 EUR | [Amazon](https://amzn.eu/d/04FdHqNl) |
| 3G/4G LTE HAT Mini, conectividad móvil para la Raspberry | 1 | 25,57 EUR | [AliExpress](https://es.aliexpress.com/item/1005007875411312.html) |
| Módulo LoRa + antena para la Raspberry (malla LoRa futura) | 1 | 8,59 EUR | [plot-advisor](https://github.com/Payasos-del-Goya/plot-advisor) |

### Total orientativo

```text
Raspberry, conectividad móvil y LoRa ≈ 224,15 EUR por finca
```

El software (Docker, PostgreSQL, InfluxDB, Mosquitto, Telegraf, Grafana e Icinga 2) no tiene licencias de pago.

El presupuesto no incluye las balizas ni el puente (ver
[crops-analyzer-module](https://github.com/Payasos-del-Goya/crops-analyzer-module#estudio-de-precio-de-ensamblaje)),
ni los costes recurrentes de Internet, de la tarifa de datos móviles ni de Meteomatics.

## Claves

Las claves son de demo y están en el propio [`compose.yaml`](compose.yaml) (bloque `x-claves`), igual que en el
resto del proyecto. El repo es público: para cualquier instalación real hay que cambiarlas ahí antes de arrancar.

## Estructura

```text
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
