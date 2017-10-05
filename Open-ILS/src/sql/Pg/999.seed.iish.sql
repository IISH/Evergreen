/*
Copyright (c) 2014-2015  International Institute of Social History

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

Author: Lucien van Wouw <lwo@iisg.nl>
*/


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

-- leader-6-8
-- xslt for the material report
INSERT INTO config.xml_transform VALUES ( 'leader-6-8', 'http://www.loc.gov/MARC21/slim', 'marc', '--' );
UPDATE config.xml_transform SET xslt=$$<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:marc="http://www.loc.gov/MARC21/slim" exclude-result-prefixes="marc"><xsl:output media-type="text" omit-xml-declaration="yes"/><xsl:template match="marc:record"><xsl:value-of select="normalize-space(substring(marc:leader/text(), 6, 3))"/></xsl:template></xsl:stylesheet>$$ WHERE name = 'leader-6-8' ;

-- controlfield-008-15-17
-- xslt for the country code
INSERT INTO config.xml_transform VALUES ( 'controlfield-008-15-17', 'http://www.loc.gov/MARC21/slim', 'marc', '--' );
UPDATE config.xml_transform SET xslt=$$<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:marc="http://www.loc.gov/MARC21/slim" exclude-result-prefixes="marc"><xsl:output media-type="text" omit-xml-declaration="yes"/><xsl:template match="marc:record"><xsl:value-of select="normalize-space(substring(marc:controlfield[@tag='008']/text(), 16, 3))"/></xsl:template></xsl:stylesheet>$$ WHERE name = 'controlfield-008-15-17' ;

-- 866$a
-- xslt for the serial holding report
INSERT INTO config.xml_transform VALUES ( '866-a', 'http://www.loc.gov/MARC21/slim', 'marc', '--' );
UPDATE config.xml_transform SET xslt=$$<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:marc="http://www.loc.gov/MARC21/slim" exclude-result-prefixes="marc"><xsl:output media-type="text" omit-xml-declaration="yes"/><xsl:template match="marc:record"><xsl:value-of select="marc:datafield[@tag='866']/marc:subfield[@code='a']"/></xsl:template></xsl:stylesheet>$$ WHERE name = '866-a' ;


-- VIEWS for the oai service
CREATE SCHEMA oai;

-- The view presents a lean table with unique bre.tc-numbers for oai paging;
CREATE VIEW oai.biblio AS
  SELECT
    bre.id                             AS tcn,
    bre.edit_date                      AS datestamp,
    bre.deleted                        AS deleted
  FROM
    biblio.record_entry bre
  ORDER BY
    bre.id;

-- The view presents a lean table with unique are.tc-numbers for oai paging;
CREATE VIEW oai.authority AS
  SELECT
    are.id               AS tcn,
    are.edit_date        AS datestamp,
    are.deleted          AS deleted
  FROM
    authority.record_entry AS are
  ORDER BY
    are.id;

-- If an edit date changes in the asset.call_number or asset.copy and you want this to persist to an OAI2 datestamp,
-- then add these stored procedures and triggers:
CREATE OR REPLACE FUNCTION oai.datestamp(rid BIGINT)
  RETURNS VOID AS $$
BEGIN
  UPDATE biblio.record_entry AS bre
  SET edit_date = now()
  WHERE bre.id = rid;
END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION oai.call_number_datestamp()
  RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE'
  THEN
    PERFORM oai.datestamp(OLD.record);
    RETURN OLD;
  END IF;

  PERFORM oai.datestamp(NEW.record);
  RETURN NEW;

END
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION oai.copy_datestamp()
  RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE'
  THEN
    PERFORM oai.datestamp((SELECT acn.record FROM asset.call_number as acn WHERE acn.id = OLD.call_number));
    RETURN OLD;
  END IF;

  PERFORM oai.datestamp((SELECT acn.record FROM asset.call_number as acn WHERE acn.id = NEW.call_number));
  RETURN NEW;

END
$$ LANGUAGE plpgsql;

CREATE TRIGGER call_number_datestamp AFTER INSERT OR UPDATE OR DELETE ON asset.call_number FOR EACH ROW EXECUTE PROCEDURE oai.call_number_datestamp();
CREATE TRIGGER copy_datestamp AFTER INSERT OR UPDATE OR DELETE ON asset.copy FOR EACH ROW EXECUTE PROCEDURE oai.copy_datestamp();


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
CREATE TABLE batch.enrich (
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
CREATE TRIGGER xslt_is_well_formed BEFORE INSERT OR UPDATE ON batch.enrich FOR EACH ROW EXECUTE PROCEDURE batch.check_xml_well_formed();

INSERT INTO permission.perm_list ( id, code, description ) VALUES
  ( 2000, 'BATCH_SCHEDULE', oils_i18n_gettext( 2000, 'BATCH_SCHEDULE', 'ppl', 'description' )) ;
INSERT INTO permission.perm_list ( id, code, description ) VALUES
  ( 2001, 'BATCH_ENRICH', oils_i18n_gettext( 2001, 'BATCH_ENRICH', 'ppl', 'description' )) ;


COMMIT ;