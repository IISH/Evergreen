#!/bin/bash
set -e


source "${OPENILS_HOME}/scripts/lib/base_functions.sh"
source "${OPENILS_HOME}/scripts/lib/functions.sh"
source "${OPENILS_HOME}/scripts/lib/base_config.sh"
source "${OPENILS_HOME}/scripts/lib/config.sh"


$DEBUG_COMMAND


run_scripts() {
    local run_script_dir="${OPENILS_HOME}/scripts/${1}"
    for script in ${run_script_dir}/*.sh
    do
        if [ -f ${script} -a -x ${script} ]
        then
            ${script}
        fi
    done
}


# pre_scripts
# Configuration of the container
pre_scripts() {
    run_scripts "pre"
}

# post_scripts
# To run after the deamon starts ( in combination with wait [pid] )
post_scripts() {
    run_scripts "post"
}

# post_scripts
# Cleanup operations that start after the main process finished.
main() {
    pre_scripts

    opt=$1
    case "$opt" in
        opensrf)
            service ejabberd restart
            /usr/sbin/ejabberdctl register $OPENSRF_PRIVATE_USER $OPENSRF_PRIVATE_DOMAIN $OPENSRF_PRIVATE_PASSWD
            /usr/sbin/ejabberdctl register $OPENSRF_PUBLIC_USER  $OPENSRF_PRIVATE_DOMAIN $OPENSRF_PUBLIC_PASSWD
            /usr/sbin/ejabberdctl register $OPENSRF_PRIVATE_USER $OPENSRF_PUBLIC_DOMAIN  $OPENSRF_PRIVATE_PASSWD
            /usr/sbin/ejabberdctl register $OPENSRF_PUBLIC_USER  $OPENSRF_PUBLIC_DOMAIN  $OPENSRF_PUBLIC_PASSWD
            service opensrf restart
            ;;
        openils)
          a2dismod mpm_event
          a2enmod mpm_prefork
          a2dissite 000-default  # OPTIONAL: disable the default site (the "It Works" page)
          a2ensite eg.conf
          chown opensrf /var/lock/apache2
          service openils restart
          ;;
        *)
            exec $@
        ;;
    esac
}


main "$@"