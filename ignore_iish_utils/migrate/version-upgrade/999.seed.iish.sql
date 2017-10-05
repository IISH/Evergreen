BEGIN;

-- marc-format
-- xslt for presenting a marc record
INSERT INTO config.xml_transform VALUES ( 'marc-format', 'http://www.loc.gov/MARC21/slim', 'marc', '--' );
UPDATE config.xml_transform SET xslt=$$<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim" exclude-result-prefixes="marc">
    <xsl:output media-type="html" omit-xml-declaration="yes"/>
    <xsl:preserve-space elements="*"/>

    <xsl:template match="marc:record">

        <table border="0" class="citation">
            <tbody>
                    <th>LEADER</th>
                    <td colspan="3">
                        <xsl:value-of select="marc:leader"/>
                    </td>
                </tr>

                <xsl:for-each select="marc:controlfield">
                    <tr>
                        <th style="text-align: right;" valign="TOP">
                            <xsl:value-of select="@tag"/>
                        </th>
                        <td colspan="3">
                            <xsl:value-of select="text()"/>
                        </td>
                    </tr>
                </xsl:for-each>

                <xsl:for-each select="marc:datafield">
                    <tr>
                        <th style="text-align: right;" valign="TOP">
                            <xsl:value-of select="@tag"/>
                        </th>
                        <td>
                            <xsl:value-of select="@ind1"/>
                        </td>
                        <td>
                            <xsl:value-of select="@ind2"/>
                        </td>
                        <td>
                            <xsl:for-each select="marc:subfield">
                                <strong>|<xsl:value-of select="@code"/></strong><xsl:value-of select="concat(' ', text())"/>
                            </xsl:for-each>
                        </td>
                    </tr>
                </xsl:for-each>

            </tbody>
        </table>

    </xsl:template>
</xsl:stylesheet>$$ WHERE name = 'marc-format' ;


-- archive-list-931
-- xslt for the archive-list-931 report
INSERT INTO config.xml_transform VALUES ( 'archive-list-931', 'http://www.loc.gov/MARC21/slim', 'marc', '--' );
UPDATE config.xml_transform SET xslt=$$<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim" exclude-result-prefixes="marc">
    <xsl:output media-type="html" omit-xml-declaration="yes"/>
    <xsl:preserve-space elements="*"/>

    <xsl:template match="marc:record">

        <table border="0" class="citation">
            <tbody>
                <!--<tr>
                    <th>LEADER</th>
                    <td colspan="3">
                        <xsl:value-of select="marc:leader"/>
                    </td>
                </tr>

                <xsl:for-each select="marc:controlfield">
                    <tr>
                        <th style="text-align: right;" valign="TOP">
                            <xsl:value-of select="@tag"/>
                        </th>
                        <td colspan="3">
                            <xsl:value-of select="text()"/>
                        </td>
                    </tr>
                </xsl:for-each>-->

                <xsl:for-each select="marc:datafield[@tag='931']">
                    <tr>
                        <th style="text-align: right;" valign="TOP">
                            <xsl:value-of select="@tag"/>
                        </th>
                        <td>
                            <xsl:value-of select="@ind1"/>
                        </td>
                        <td>
                            <xsl:value-of select="@ind2"/>
                        </td>
                        <td>
                            <xsl:for-each select="marc:subfield">
                                <strong>|<xsl:value-of select="@code"/></strong><xsl:value-of select="concat(' ', text())"/>
                            </xsl:for-each>
                        </td>
                    </tr>
                </xsl:for-each>

            </tbody>
        </table>

        <p>
            <a>
                <xsl:attribute name="href">
                    <xsl:value-of select="concat('http://api.socialhistoryservices.org/solr/all/srw?query=dc.identifier+%3D+%22', marc:controlfield[@tag='001'], '%22&amp;version=1.1&amp;operation=searchRetrieve&amp;recordSchema=info%3Asrw%2Fschema%2F1%2Fmarcxml-v1.1&amp;maximumRecords=1&amp;startRecord=1')"/>
                </xsl:attribute>
                Show access status
            </a>
        </p>

    </xsl:template>
</xsl:stylesheet>$$ WHERE name = 'archive-list-931' ;


-- archive-length
-- xslt for the archive-length report
INSERT INTO config.xml_transform VALUES ( 'archive-length', 'http://www.loc.gov/MARC21/slim', 'marc', '--' );
UPDATE config.xml_transform SET xslt=$$<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:marc="http://www.loc.gov/MARC21/slim" exclude-result-prefixes="marc"><xsl:output media-type="text" omit-xml-declaration="yes"/><xsl:template match="marc:record"><xsl:value-of select="sum(marc:datafield[@tag='931']/marc:subfield[@code='b'])"/></xsl:template></xsl:stylesheet>$$ WHERE name = 'archive-length' ;

-- 008-material
-- xslt for the material report
INSERT INTO config.xml_transform VALUES ( 'leader-6-8', 'http://www.loc.gov/MARC21/slim', 'marc', '--' );
UPDATE config.xml_transform SET xslt=$$<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:marc="http://www.loc.gov/MARC21/slim" exclude-result-prefixes="marc"><xsl:output media-type="text" omit-xml-declaration="yes"/><xsl:template match="marc:record"><xsl:value-of select="normalize-space(substring(marc:leader/text(), 6, 3))"/></xsl:template></xsl:stylesheet>$$ WHERE name = 'leader-6-8' ;


-- VIEWS for the oai service
CREATE SCHEMA oai;

CREATE OR REPLACE FUNCTION oai.edit_date( TIMESTAMPTZ , TIMESTAMPTZ, TIMESTAMPTZ, TIMESTAMPTZ ) RETURNS TIMESTAMPTZ AS $$
    my ($date, $d2, $d3, $d4 ) = @_ ;

    $date = $d2 if ( $d2 > $date ) ;
    $date = $d3 if ( $d3 > $date ) ;
    $date = $d4 if ( $d4 > $date ) ;
    return $date ;

$$ LANGUAGE PLPERLU STRICT IMMUTABLE;


CREATE VIEW oai.record AS SELECT bre.id as tcn, max(acnn.owning_lib) as owning_lib,
  oai.edit_date(
    max(bre.edit_date),
    coalesce(max(acnn.edit_date), timestamptz('1970-01-01T00:00:00Z')),
    coalesce(max(acpl.edit_date), timestamptz('1970-01-01T00:00:00Z')),
    coalesce(max(sre.edit_date), timestamptz('1970-01-01T00:00:00Z'))
    ) as edit_date, bre.deleted as deleted
FROM biblio.record_entry bre
  JOIN asset.call_number acnn ON (acnn.record = bre.id)
  JOIN asset.copy acpl ON (acpl.call_number = acnn.id)
  LEFT OUTER JOIN serial.record_entry sre ON (sre.record = bre.id ) WHERE bre.active = true GROUP BY tcn ORDER BY bre.id;


-- create table for the batch update server.
CREATE SCHEMA batch;
CREATE TABLE batch.schedule (
	id		SERIAL				PRIMARY KEY,
  title TEXT NOT NULL,
	runner		INT				NOT NULL REFERENCES actor.usr (id) DEFERRABLE INITIALLY DEFERRED,
	start_time	TIMESTAMP WITH TIME ZONE,
  complete_time	TIMESTAMP WITH TIME ZONE,
  heartbeat_time	TIMESTAMP WITH TIME ZONE,
  run_time	TIMESTAMP WITH TIME ZONE	NOT NULL DEFAULT NOW(),
  repeat INT DEFAULT 0,
  email		TEXT,
  report_url	TEXT				NOT NULL,
  xslt  TEXT NOT NULL DEFAULT '<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="http://www.loc.gov/MARC21/slim" xmlns:marc="http://www.loc.gov/MARC21/slim"><xsl:output omit-xml-declaration="yes" indent="no"/><xsl:template match="@*|node()"><xsl:copy><xsl:apply-templates select="@*|node()"></xsl:apply-templates></xsl:copy></xsl:template></xsl:stylesheet>',
  records_changed INT DEFAULT 0,
  records_unchanged INT DEFAULT 0,
  records_failed INT DEFAULT 0,
  records_total INT DEFAULT 0,
  status	INT DEFAULT 0,
  error_code	INT,
	error_text	TEXT
);
CREATE OR REPLACE FUNCTION batch.check_xml_well_formed () RETURNS TRIGGER AS $func$
BEGIN

  IF xml_is_well_formed(NEW.xslt) THEN
    RETURN NEW;
  ELSE
    RAISE EXCEPTION 'Attempted to % xslt that is not well formed', TG_OP;
  END IF;

END;
$func$ LANGUAGE PLPGSQL;
CREATE TRIGGER xslt_is_well_formed BEFORE INSERT OR UPDATE ON batch.schedule FOR EACH ROW EXECUTE PROCEDURE batch.check_xml_well_formed();

INSERT INTO permission.perm_list ( id, code, description ) VALUES
  ( 2000, 'BATCH_SCHEDULE', oils_i18n_gettext( 2000, 'BATCH_SCHEDULE', 'ppl', 'description' )) ;


COMMIT ;