#!/bin/bash
# Instala plot-advisor (backend + frontend en contenedores) en la Raspberry fieldshift-gw.
#
# Espera los tres repos como carpetas hermanas en /opt/plotadvisor:
#   /opt/plotadvisor/crops-analyzer-infra      (este repo)
#   /opt/plotadvisor/crops-analyzer-backend
#   /opt/plotadvisor/crops-analyzer-frontend
#
# Uso:  sudo /opt/plotadvisor/crops-analyzer-infra/raspberry/instalar.sh
# Se puede repetir: vuelve a construir las imágenes y reinicia los servicios (así se actualiza tras un git pull).
set -euo pipefail

BASE=/opt/plotadvisor
INFRA=$BASE/crops-analyzer-infra
COMPOSE=(docker compose -p plotadvisor -f "$INFRA/compose.yaml" -f "$INFRA/raspberry/compose.raspberry.yaml")

[ "$(id -u)" = 0 ] || { echo "Ejecutar con sudo"; exit 1; }
for d in crops-analyzer-infra crops-analyzer-backend crops-analyzer-frontend; do
  [ -d "$BASE/$d" ] || { echo "Falta $BASE/$d"; exit 1; }
done

# Docker sin tocar el cortafuegos: si lo tocara, los dispositivos de la WiFi GatewayPA se quedarían sin Internet.
if ! grep -q '"iptables": *false' /etc/docker/daemon.json 2>/dev/null; then
  echo "/etc/docker/daemon.json debe tener \"iptables\": false (ver raspberry/README.md)"; exit 1
fi

echo "== Paquetes"
command -v avahi-publish >/dev/null || apt-get install -y -q avahi-utils

echo "== Apache (http://plotadvisor.local)"
a2enmod -q proxy proxy_http proxy_wstunnel
install -m 644 "$INFRA/raspberry/apache/plotadvisor.conf" /etc/apache2/sites-available/plotadvisor.conf
a2ensite -q plotadvisor
apachectl configtest
systemctl reload apache2

echo "== Servicios de systemd"
install -m 644 "$INFRA"/raspberry/systemd/plotadvisor-*.service /etc/systemd/system/
systemctl daemon-reload

echo "== Imágenes (la primera vez tarda unos minutos)"
BACKEND_SRC=$BASE/crops-analyzer-backend FRONTEND_SRC=$BASE/crops-analyzer-frontend "${COMPOSE[@]}" build backend frontend

echo "== Arranque"
systemctl enable -q plotadvisor-mdns plotadvisor-backend plotadvisor-frontend
systemctl restart plotadvisor-mdns plotadvisor-backend plotadvisor-frontend
systemctl --no-pager --lines=0 status plotadvisor-backend plotadvisor-frontend plotadvisor-mdns | grep -E "●|Active"
echo "Listo: http://plotadvisor.local (desde la WiFi GatewayPA)"
