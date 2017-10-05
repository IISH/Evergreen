<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://www.loc.gov/MARC21/slim"
                xmlns:marc="http://www.loc.gov/MARC21/slim">
    <xsl:output omit-xml-declaration="yes" indent="no"/>

    <xsl:param name="pid"/>

    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="marc:datafield[@tag='901']">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
        <xsl:element name="datafield">
            <xsl:attribute name="tag">902</xsl:attribute>
            <xsl:attribute name="ind1"><xsl:value-of select="' '"/></xsl:attribute>
            <xsl:attribute name="ind2"><xsl:value-of select="' '"/></xsl:attribute>
            <xsl:element name="subfield">
                <xsl:attribute name="code">a</xsl:attribute>
                <xsl:value-of select="$pid"/>
            </xsl:element>
        </xsl:element>
    </xsl:template>

    <xsl:template match="marc:datafield[@tag='856' and contains(marc:subfield[@code='u']/text(), '/10622/30051')]">
        <xsl:if test="count(marc:subfield)>1">
            <xsl:copy>
                <xsl:apply-templates select="node()|@*"/>
            </xsl:copy>
        </xsl:if>
    </xsl:template>

    <xsl:template match="marc:datafield[@tag='902']"/>

</xsl:stylesheet>
