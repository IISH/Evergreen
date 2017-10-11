#!/bin/bash
set -e

source "${OPENILS_HOME}/scripts/lib/base_functions.sh"
source "${OPENILS_HOME}/scripts/lib/functions.sh"
source "${OPENILS_HOME}/scripts/lib/base_config.sh"
source "${OPENILS_HOME}/scripts/lib/config.sh"


make_config_file() {
    cnf_file=$1
    tpl_file=$2
    echo "Generating config file ${cnf_file}..."
    cp "$tpl_file" "$cnf_file"
}

make_config_template() {
    cnf_file=$1
    tpl_file=$2
    echo "Generating config file ${cnf_file}..."
    cat "$tpl_file" | python -c "${PYTHON_JINJA2}" > "$cnf_file"
}


# generate config files
main() {
    for cnf_key in $CNF_KEYS
    do
        cnf_file=$(eval echo "\$CNF_${cnf_key}")
        if [ -z "$cnf_file" ]
        then
            echo -e "Error: cnf_file ${cnf_key} is empty. Invalid key-value configuration."
            exit 1
        fi
        tpl_file=$(eval echo "\$TPL_${cnf_key}")
        if [ -z "$tpl_file" ]
        then
            echo -e "Error: tpl_file ${tpl_file} is empty. Invalid key-value configuration."
            exit 1
        fi

        filename=$(basename "$tpl_file")
        extension="${filename##*.}"
        if [ "$extension" == "tpl" ]
        then
            make_config_template "$cnf_file" "$tpl_file"
        else
            make_config_file "$cnf_file" "$tpl_file"
        fi
    done
}

main

exit 0
