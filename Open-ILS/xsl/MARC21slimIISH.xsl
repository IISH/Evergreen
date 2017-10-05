<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim">
    <xsl:output indent="no"/>

    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="*">
        <xsl:element name="marc:{name()}" namespace="http://www.loc.gov/MARC21/slim">
            <xsl:copy-of select="namespace::*"/>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:element>
    </xsl:template>

    <xsl:template match="marc:datafield[@tag='852' and marc:subfield[@code='p']]">
        <xsl:element name="marc:{name()}" namespace="http://www.loc.gov/MARC21/slim">
            <xsl:copy-of select="namespace::*"/>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:element>
        <xsl:variable name="barcode" select="normalize-space( marc:subfield[@code='p']/text())"/>
        <xsl:if test="starts-with($barcode, '30051')">
            <marc:datafield tag="'856">
                <marc:subfield code="u">
                    <xsl:value-of select="concat('http://hdl.handle.net/10622/', marc:subfield[@code='p'])"/>
                </marc:subfield>
            </marc:datafield>
        </xsl:if>
    </xsl:template>

</xsl:stylesheet>