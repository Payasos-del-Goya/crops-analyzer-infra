#!/bin/sh
# Crea el fichero de contraseñas y la ACL de Mosquitto con los usuarios de compose.yaml y arranca el broker.
# Telegraf solo lee (datos y $SYS); las balizas leen y escriben.
set -e
: "${MQTT_BALIZAS_USER:?falta MQTT_BALIZAS_USER}" "${MQTT_BALIZAS_PASSWORD:?}" "${MQTT_TELEGRAF_PASSWORD:?}"
f=/mosquitto/data/passwd
rm -f "$f"
touch "$f"
chmod 0700 "$f"
mosquitto_passwd -b "$f" "$MQTT_BALIZAS_USER" "$MQTT_BALIZAS_PASSWORD"
mosquitto_passwd -b "$f" telegraf "$MQTT_TELEGRAF_PASSWORD"
cat > /mosquitto/data/acl <<ACL
user telegraf
topic read \$SYS/#
topic read #

user $MQTT_BALIZAS_USER
topic readwrite #
ACL
chown mosquitto:mosquitto "$f" /mosquitto/data/acl
exec /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf
