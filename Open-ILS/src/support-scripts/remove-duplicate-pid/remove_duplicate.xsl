<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim">

    <xsl:variable name="pids" select="document('/data/reporter/pids.xml')"/>
    <xsl:variable name="tcn" select="marc:record/marc:controlfield[@tag='001']"/>

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="marc:datafield[@tag='902']/marc:subfield[@code='a']/text()">
        <xsl:variable name="pid" select="$pids/records/p[@t=$tcn]"/>
        <xsl:choose>
            <xsl:when test="string-length($pid)=0"><xsl:value-of select="."/></xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$pid"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
