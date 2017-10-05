<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

    <xsl:output method="xml" indent="no"/>

    <xsl:template match="marc:record">
        <marc:record xmlns:marc="http://www.loc.gov/MARC21/slim" xsi:schemaLocation="http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd">
            <marc:leader><xsl:value-of select="marc:leader"/></marc:leader>
            <xsl:for-each select="marc:controlfield">
                <marc:controlfield tag="{@tag}"><xsl:value-of select="text()"/></marc:controlfield>
            </xsl:for-each>
            <xsl:for-each select="marc:datafield">
                <marc:datafield tag="{@tag}" ind1="{@ind1}" ind2="{@ind2}">
                    <xsl:for-each select="marc:subfield">
                        <marc:subfield code="{@code}"><xsl:value-of select="text()"/></marc:subfield>
                    </xsl:for-each>
                </marc:datafield>
            </xsl:for-each>
        </marc:record>
    </xsl:template>

</xsl:stylesheet>