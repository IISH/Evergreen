<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim">

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="marc:leader/text()">
            <xsl:value-of select="concat( substring(normalize-space(.), 0, 13), '     7a 4500')" />
    </xsl:template>

    <xsl:template match="marc:controlfield[@tag='008']/text()">
        <xsl:value-of select="translate(normalize-space(.), '|', ' ')"/>
    </xsl:template>

</xsl:stylesheet>