#!/usr/bin/env bashio
set -e

DIRSFIRST=$(bashio::config 'dirsfirst')
ENFORCE_BASEPATH=$(bashio::config 'enforce_basepath')
WAIT_PIDS=()

# Setup and run Frontend
sed -i "s/%%PORT%%/8080/g" /etc/nginx/nginx-ingress.conf
sed -i "s/%%PORT_INGRESS%%/8099/g" /etc/nginx/nginx-ingress.conf

nginx -c /etc/nginx/nginx-ingress.conf &
WAIT_PIDS+=($!)

# Setup and run configurator
sed -i "s/%%TOKEN%%/${HASSIO_TOKEN}/g" /etc/configurator.conf
sed -i "s/%%DIRSFIRST%%/${DIRSFIRST}/g" /etc/configurator.conf
sed -i "s/%%ENFORCE_BASEPATH%%/${ENFORCE_BASEPATH}/g" /etc/configurator.conf

hass-configurator /etc/configurator.conf &
WAIT_PIDS+=($!)

# Register stop
function stop_addon() {
    bashio::log.debug "Kill Processes..."
    kill -15 "${WAIT_PIDS[@]}"
    wait "${WAIT_PIDS[@]}"
    bashio::log.debug "Done."
}
trap "stop_addon" SIGTERM SIGHUP

# Wait until all is done
bashio::log.info "Add-on running"
wait "${WAIT_PIDS[@]}"
