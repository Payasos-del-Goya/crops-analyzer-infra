# Despliegue en la Raspberry `fieldshift-gw`

En la Raspberry de la demo, PostgreSQL, InfluxDB, Mosquitto, Telegraf, Grafana e Icinga ya van instalados. Aquí solo
se añaden **el backend y el frontend en contenedores**, cada uno con su servicio de systemd, y el nombre
**http://plotadvisor.local** para entrar desde la WiFi `GatewayPA`.

## Instalar o actualizar

1. Los tres repos en `/opt/plotadvisor` (como carpetas hermanas):
   ```
   /opt/plotadvisor/crops-analyzer-infra
   /opt/plotadvisor/crops-analyzer-backend
   /opt/plotadvisor/crops-analyzer-frontend
   ```
2. Docker sin tocar el cortafuegos (**antes** de instalarlo; si no, los dispositivos de la WiFi se quedan sin Internet):
   ```bash
   echo '{"iptables": false, "ip6tables": false, "log-driver": "journald"}' | sudo tee /etc/docker/daemon.json
   sudo apt install docker.io docker-compose docker-buildx
   ```
3. Instalar:
   ```bash
   sudo /opt/plotadvisor/crops-analyzer-infra/raspberry/instalar.sh
   ```
   Construye las imágenes, configura Apache y arranca los servicios. Para actualizar tras cambiar el código, se
   vuelve a ejecutar.

## Uso diario

```bash
sudo systemctl status  plotadvisor-backend plotadvisor-frontend
sudo systemctl restart plotadvisor-backend      # o plotadvisor-frontend
sudo systemctl stop    plotadvisor-frontend
journalctl -u plotadvisor-backend -f            # logs
```

| Servicio | Qué es | Escucha en |
|---|---|---|
| `plotadvisor-backend` | FastAPI (contenedor `plotadvisor-backend-1`) | 127.0.0.1:8000 |
| `plotadvisor-frontend` | Next.js (contenedor `plotadvisor-frontend-1`) | 127.0.0.1:3001 (el 3000 es de Grafana) |
| `plotadvisor-mdns` | publica `plotadvisor.local` → 10.42.0.1 | mDNS |
| Apache (`plotadvisor.conf`) | `http://plotadvisor.local` → frontend; `/api/ws/` → backend | :80 |

Icinga Web sigue en `http://plotadvisor.local/icingaweb2` y Grafana en `http://plotadvisor.local:3000`.

## Detalles

- **Red del anfitrión** (`network_mode: host`): con `"iptables": false` Docker no crea redes con salida a Internet,
  así que los contenedores usan la red de la Raspberry. El backend lee InfluxDB y PostgreSQL en 127.0.0.1 con las
  claves por defecto de su `config.py` (las de esta Raspberry).
- **`plotadvisor.local`** se anuncia por mDNS con la IP de la WiFi (10.42.0.1): funciona desde los dispositivos
  conectados a `GatewayPA` (Mac, iPhone, Android reciente, Windows 10+, Linux con avahi).
- El clima de Meteomatics que guarda el backend vive en el volumen `plotadvisor_backend-cache`. Docker crea también
  `plotadvisor_postgres`, `_influxdb`, `_grafana` y `_mosquitto` (los del compose completo): aquí quedan vacíos.
- El backend reentrena el modelo al arrancar (~5 s): la imagen lleva scikit-learn 1.9.1 y el `.joblib` es de la 1.6.1.
