#!/bin/bash

p="/usr/local/share/perl/5.14.2/OpenILS/WWW/OAI.pm"
perl $p
rc=$?
if [ $rc != 0 ] ; then
	echo "Errors in $p"
	exit $rc
fi

echo "">/var/log/syslog
echo "">/var/log/openils/osrfsys.log

#sudo -u opensrf /bin/bash -c "PATH=${PATH}:/openils/bin osrf_control --restart --service open-ils.report"
#sudo -u opensrf /bin/bash -c "PATH=${PATH}:/openils/bin osrf_control --restart --service open-ils.oai"

#f="Identify.txt"
#rm $f
#wget -O $f "http://10.0.0.100/opac/extras/oai2?verb=Identify"
#cat $f

#f="ListMetadataFormats.txt"
#rm $f
#wget -O $f "http://10.0.0.100/opac/extras/oai2?verb=ListMetadataFormats"
#cat $f

#f="ListSets.txt"
#rm $f
#wget -O $f "http://10.0.0.100/opac/extras/oai2?verb=ListSets"
#cat $f

#f="GetRecord.txt"
#rm $f
#wget -O $f "http://10.0.0.100/opac/extras/oai2?metadataPrefix=marcxml&verb=GetRecord&identifier=oai:evergreen.iisg.nl:100"
#cat $f


#f="ListIdentifiers.txt"
#rm $f
#wget -O $f "http://10.0.0.100/opac/extras/oai2?verb=ListIdentifiers&resumptionToken=bWFyY3htbDoyMDE0LTAxLTAxOjo6MjAw"
#cat $f


f="listRecords.txt"
rm $f
wget -O $f "http://10.0.0.100/opac/extras/oai2?verb=ListRecords&metadataPrefix=marcxml"
cat $f

cat /var/log/syslog
