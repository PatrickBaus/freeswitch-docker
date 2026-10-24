#!/bin/sh
# Seed the FreeSWITCH configuration directory when a volume or bind mount
# hides the default configuration that was installed in the image.
set -e

CONF_DIR="${FREESWITCH_CONF_DIR:-/etc/freeswitch}"
DEFAULT_CONF_DIR="${FREESWITCH_DEFAULT_CONF_DIR:-/usr/share/freeswitch/conf.default}"

if [ ! -e "${CONF_DIR}/freeswitch.xml" ]; then
  if [ -z "$(ls -A "${CONF_DIR}" 2>/dev/null)" ]; then
    echo "entrypoint: ${CONF_DIR} is empty, seeding it with the default configuration"
    mkdir -p "${CONF_DIR}"
    cp -a "${DEFAULT_CONF_DIR}/." "${CONF_DIR}/"
  else
    echo "entrypoint: WARNING: ${CONF_DIR} is not empty but contains no freeswitch.xml, leaving it untouched" >&2
  fi
fi

exec "$@"
