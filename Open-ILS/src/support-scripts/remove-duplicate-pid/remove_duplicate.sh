#!/bin/bash
#
# remove_duplicate [file with tcn and PID columns] [pid webservice key]
#
# Description
# Rebind the Handle


file="$1"
if [ ! -f "$file" ]
then
    echo "File not found: ${file}"
    ecit 1
fi

catalog="https://search.socialhistory.org/Record"
na="10622"
pidwebservice_endpoint="https://pid.socialhistoryservices.org/secure/"
pidwebservice_key="$2"
if [ -z "$pidwebservice_key" ]
then
    echo "pidwebservice_key not set."
    exit 1
fi


while read line
do
    IFS=, read tcn pid <<< "$line"
    soapenv="<?xml version='1.0' encoding='UTF-8'?>  \
		<soapenv:Envelope xmlns:soapenv='http://schemas.xmlsoap.org/soap/envelope/' xmlns:pid='http://pid.socialhistoryservices.org/'>  \
			<soapenv:Body> \
				<pid:UpsertPidRequest> \
					<pid:na>$na</pid:na> \
					<pid:handle> \
						<pid:pid>$pid</pid:pid> \
						<pid:resolveUrl>${catalog}/${tcn}</pid:resolveUrl> \
					</pid:handle> \
				</pid:UpsertPidRequest> \
			</soapenv:Body> \
		</soapenv:Envelope>"

    wget -O /dev/null -S \
        --no-check-certificate \
        --header="Content-Type: text/xml" \
        --header="Authorization: bearer ${pidwebservice_key}" \
        --post-data "$soapenv" \
        "$pidwebservice_endpoint"
    rc=$?
    if [[ $rc == 0 ]]
    then
        echo "Ok... $line"
    else
        echo "Error ${rc} ${line}"
    fi

done < "$file"

