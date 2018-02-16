#!/bin/bash


if [ ! -f lijst.txt ]
then
    while read tcn
    do
        uuid=$(/usr/bin/uuidgen)
        uuid="10622/${uuid^^}"
        mongo handlesystem --quiet --eval "var doc=db.handles_10622.findOne({_lookup:'http://search.socialhistory.org/Record/${tcn}'});if (doc) {print('1 ${tcn} '+doc.handle)} else {print('0 ${tcn} ${uuid}')};" >> lijst.txt
    done < tcn.txt
fi

echo "<xsl:choose>"
while read line
do
    read n tcn pid <<< "$line"
    echo "<xsl:when test=\"\$t=$tcn\">$pid</xsl:when>"
done < lijst.txt

echo "<xsl:otherwise><xsl:value-of select=\"\$t\"/></xsl:otherwise>"
echo "</xsl:choose>"