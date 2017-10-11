#!/bin/bash
set -e

source "${OPENILS_HOME}/scripts/lib/base_functions.sh"
source "${OPENILS_HOME}/scripts/lib/functions.sh"
source "${OPENILS_HOME}/scripts/lib/base_config.sh"
source "${OPENILS_HOME}/scripts/lib/config.sh"


main() {
    chown -R $OPENSRF_USER:$OPENSRF_USER "$OPENILS_SYSDIR"
    chown -R $OPENSRF_USER:$OPENSRF_USER "$OPENSRF_HOME"
}


main

exit 0
