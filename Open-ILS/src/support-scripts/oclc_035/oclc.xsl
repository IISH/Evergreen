<?xml version="1.0" encoding="UTF-8"?>
<!--

Add the OCLC number in the 035$a field.

-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim">

    <xsl:variable name="oclc0" select="document('/data/reporter/oclc0.xml')"/>
    <xsl:variable name="oclc1" select="document('/data/reporter/oclc1.xml')"/>
    <xsl:variable name="oclc2" select="document('/data/reporter/oclc2.xml')"/>
    <xsl:variable name="oclc3" select="document('/data/reporter/oclc3.xml')"/>
    <xsl:variable name="oclc4" select="document('/data/reporter/oclc4.xml')"/>
    <xsl:variable name="oclc5" select="document('/data/reporter/oclc5.xml')"/>
    <xsl:variable name="oclc6" select="document('/data/reporter/oclc6.xml')"/>
    <xsl:variable name="oclc7" select="document('/data/reporter/oclc7.xml')"/>
    <xsl:variable name="oclc8" select="document('/data/reporter/oclc8.xml')"/>
    <xsl:variable name="oclc9" select="document('/data/reporter/oclc9.xml')"/>
    <xsl:variable name="tcn" select="marc:record/marc:controlfield[@tag='001']"/>

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

    <xsl:template match="marc:datafield[@tag='040']">

        <xsl:variable name="t" select="substring($tcn, string-length($tcn), 1)"/>
        <xsl:variable name="oclc">
        <xsl:choose>
            <xsl:when test="$t = 0"><xsl:value-of select="$oclc0/records/r[t=$tcn]/o"/></xsl:when>
            <xsl:when test="$t = 1"><xsl:value-of select="$oclc1/records/r[t=$tcn]/o"/></xsl:when>
            <xsl:when test="$t = 2"><xsl:value-of select="$oclc2/records/r[t=$tcn]/o"/></xsl:when>
            <xsl:when test="$t = 3"><xsl:value-of select="$oclc3/records/r[t=$tcn]/o"/></xsl:when>
            <xsl:when test="$t = 4"><xsl:value-of select="$oclc4/records/r[t=$tcn]/o"/></xsl:when>
            <xsl:when test="$t = 5"><xsl:value-of select="$oclc5/records/r[t=$tcn]/o"/></xsl:when>
            <xsl:when test="$t = 6"><xsl:value-of select="$oclc6/records/r[t=$tcn]/o"/></xsl:when>
            <xsl:when test="$t = 7"><xsl:value-of select="$oclc7/records/r[t=$tcn]/o"/></xsl:when>
            <xsl:when test="$t = 8"><xsl:value-of select="$oclc8/records/r[t=$tcn]/o"/></xsl:when>
            <xsl:when test="$t = 9"><xsl:value-of select="$oclc9/records/r[t=$tcn]/o"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="''"/></xsl:otherwise>
        </xsl:choose>
        </xsl:variable>

        <xsl:if test="string-length($oclc)>0">
            <marc:datafield ind1=" " ind2=" " tag="035">
                <marc:subfield code="a">
                    <xsl:value-of select="concat('(OCoLC)', $oclc)"/>
                </marc:subfield>
            </marc:datafield>
        </xsl:if>

        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>

    </xsl:template>

</xsl:stylesheet>
