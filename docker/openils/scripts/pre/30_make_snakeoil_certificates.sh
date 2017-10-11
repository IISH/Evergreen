#!/bin/bash
set -e

source "${OPENILS_HOME}/scripts/lib/base_functions.sh"
source "${OPENILS_HOME}/scripts/lib/functions.sh"
source "${OPENILS_HOME}/scripts/lib/base_config.sh"
source "${OPENILS_HOME}/scripts/lib/config.sh"


make_snakeoil_certificate() {
    local domain=$1
    local file_cert=$2
    local file_key=$3
    openssl req -subj "/CN=${domain}" \
                -new \
                -newkey rsa:4096 \
                -days 365 \
                -nodes \
                -x509 \
                -keyout "$file_key" \
                -out "$file_cert"
}


main() {
    domain=$(get_ipaddress)
    file_cert=/etc/ssl/certs/ssl-cert-snakeoil.pem
    file_key=/etc/ssl/private/ssl-cert-snakeoil.key
    make_snakeoil_certificate "$domain" "$file_cert" "$file_key"
}


main

exit 0
