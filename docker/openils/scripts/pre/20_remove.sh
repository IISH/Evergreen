#!/bin/bash
set -e

source "${OPENILS_HOME}/scripts/lib/base_functions.sh"
source "${OPENILS_HOME}/scripts/lib/functions.sh"
source "${OPENILS_HOME}/scripts/lib/base_config.sh"
source "${OPENILS_HOME}/scripts/lib/config.sh"


remove_config() {
    file=$1
    if [ -f "$file" ]
    then
        rm "$file"
    fi
}


# generate config files
main() {
    remove_config "/etc/apache2/sites-enabled/000-default"
}

main

exit 0
