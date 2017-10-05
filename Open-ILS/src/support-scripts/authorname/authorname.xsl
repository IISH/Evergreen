<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim" exclude-result-prefixes="marc ">

    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="marc:datafield[@tag='245']/marc:subfield[@code='a' and text()='[Photo.]']/text()">
        <xsl:variable name="toevoeging_titel">
            <xsl:call-template name="author">
                <xsl:with-param name="name" select="normalize-space(//marc:datafield[@tag='600'][1]/marc:subfield[@code='a'])"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:choose><xsl:when test="string-length($toevoeging_titel)=0">
            <xsl:value-of select="."/></xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="concat('Photo / ', $toevoeging_titel)"/>
            </xsl:otherwise></xsl:choose>
    </xsl:template>

    <xsl:template name="author">
        <xsl:param name="name"/>
        <xsl:if test="string-length($name)!=0">
            <xsl:variable name="firstnames" select="normalize-space(substring-after($name, ','))"/>
            <xsl:variable name="lastnames" select="normalize-space(substring-before($name, ','))"/>
            <xsl:choose>
                <xsl:when test="substring($firstnames, string-length($firstnames) ) = '.'">
                    <xsl:value-of select="concat(substring($firstnames, 1, string-length($firstnames) -1), ' ', $lastnames)"/>
                </xsl:when>
                <xsl:otherwise><xsl:value-of select="concat($firstnames, ' ', $lastnames)"/></xsl:otherwise>
            </xsl:choose>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>