# To override use functions.sh


is_set() {
    local var=$1
    [[ -n $var ]]
}


is_zero() {
    local var=$1
    [[ -z $var ]]
}


file_exist() {
    local file=$1
    [[ -e $file ]]
}


is_true() {
    local var=${1,,}
    local choices=("yes" "1" "y" "true")
    for ((i=0;i < ${#choices[@]};i++)) {
        [[ "${choices[i]}" == $var ]] && return 0
    }
    return 1
}


# overwrite this function to get hostname from other sources
# like dns or etcd
get_nodename() {
    echo ${HOSTNAME}
}


# Return the IP address. We expect it to be the first line that matches the hostname.
get_ipaddress() {
  grep -m 1 "$HOSTNAME\$" /etc/hosts | grep -Eo '([0-9]*\.){3}[0-9]{1,3}'
}

get_fqdn() {
    perl -MNet::Domain -e 'print Net::Domain::hostfqdn();'
}

pause() {
    while true
    do
        echo "Ok"
        sleep 1m
    done
}

monitor_wait() {
    set +e
    echo "Waiting for the routers to come online."
    rc=-1
    while [[ $rc != 0 ]]
    do
        sleep 60s
        sudo -u $OPENSRF_USER /bin/bash -c "PATH=${PATH}:${OPENSRF_SYSDIR}/bin perl ${OPENILS_SYSDIR}/bin/monitor.pl"
        rc=$?
    done
    set -e
}

monitor_exit_on_error() {
    set -e
    while [[ true ]]
    do
        echo "Health check..."
        sudo -u $OPENSRF_USER /bin/bash -c "PATH=${PATH}:${OPENSRF_SYSDIR}/bin perl ${OPENILS_SYSDIR}/bin/monitor.pl"
        sleep 60s
    done
}