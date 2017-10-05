<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim">

	<xsl:template match="@*|node()">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()"/>
		</xsl:copy>
	</xsl:template>

    <xsl:template match="marc:subfield[@code='0']">
        <xsl:variable name="authority" select="normalize-space(.)"/>
        <marc:subfield code="0">
        <xsl:choose>
            <xsl:when test="$authority='(NL-AMISG)370811'">(NL-AMISG)370814</xsl:when>
            <xsl:when test="$authority='(NL-AMISG)370812'">(NL-AMISG)370814</xsl:when>
            <xsl:when test="$authority='(NL-AMISG)370813'">(NL-AMISG)370814</xsl:when>
            <xsl:otherwise><xsl:value-of select="$authority"/></xsl:otherwise>
        </xsl:choose>
        </marc:subfield>
    </xsl:template>

</xsl:stylesheet>
