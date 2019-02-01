<?xml version="1.0" encoding="UTF-8"?>
<!--

Add the OCLC number in the 035$a field.

-->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim">

    <xsl:variable name="oclc0" select="document('/data/reporter/oclc0.xml')"/>
    <xsl:variable name="tcn" select="marc:record/marc:controlfield[@tag='001']"/>

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

    <xsl:template match="marc:datafield[@tag='040']">

        <xsl:variable name="oclc" select="$oclc0/records/r[t=$tcn]/o"/>

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
