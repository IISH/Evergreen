# oai-openils is an openSRF service

This module is an optional service that exposes your catalog through the [OAI2 protocol](http://www.openarchives.org/OAI/openarchivesprotocol.html).

## 1. Intended behaviour

### 1.1 Entry points
There are two: one for bibliographic records and one for authority records:

    http://your-domain/opac/extras/oai/authority
    http://your-domain/opac/extras/oai/biblio
 
### 1.2 Setspec are not implemented

This is a work in progress and not enabled. The aim is to have the owning library determine the set hierarchy. The Concerto
test database for example has a record with tcn #1. This record is so popular it has copies attached to library units
"Example Branch 1", "Example Branch 2", "Example Branch 3", "Example Bookmobile 1" which is a child of Branch 3 and
"Example Branch 4". This entire kinship is expressed as sets like so: 

```xml
<header>
    ...
    <setSpec>CONS</setSpec>
    <setSpec>CONS:SYS1</setSpec>
    <setSpec>CONS:SYS2</setSpec>
    <setSpec>CONS:SYS1:BR1</setSpec>
    <setSpec>CONS:SYS1:BR2</setSpec>
    <setSpec>CONS:SYS2:BR3</setSpec>
    <setSpec>CONS:SYS2:BR4</setSpec>
    <setSpec>CONS:SYS2:BR3:BM1</setSpec>
</header>
```
Likewise the setSpecs of authority records are derived from their browse axis ( Title, Author, Subject and Topic ).

### 1.3 OAI2 datestamp

The edit date of the bibliographic and authority record is used as datestamp. If you want the date for editorial updates
of bibliographic assets ( copies, call numbers ) reflected in the datestamp, then add the triggers shown below.

### 1.4 Bibliographic mapping of assets to 852 subfields

Certain attributes asset are placed into 852 subfields so:

| subfield code | asset resource |
| --- | --- |
| a | location |
| b | owning_lib |
| c | callnumber |
| d | circlib |
| g | barcode |
| n | status |
 
Thus the Concerto with tcn #1 will have it's 852 subfields expressed as:
```xml
<marc:datafield ind1="4" ind2=" " tag="852">
    <marc:subfield code="a">Stacks</marc:subfield>
    <marc:subfield code="b">BR4</marc:subfield>
    <marc:subfield code="c">ML 60 R100</marc:subfield>
    <marc:subfield code="d">BR4</marc:subfield>
    <marc:subfield code="g">CONC70000435</marc:subfield>
    <marc:subfield code="n">Checked out</marc:subfield>
</marc:datafield>
```
This mapping can be customized and extended with static subfields:
```xml
    <marc:subfield code="q">A constant value</marc:subfield>
```

### 1.5 Default configuration

All default configuration is commented in the open-ils.oai app_settings element. See below for details on how to
override defaults by removing the comments and substitute the values.

## 2. Installation

### 2.1 Perl modules

Lookup the Perl handler and the associated openils module:

 - [Open-ILS/src/perlmods/lib/OpenILS/WWW/OAI.pm](Open-ILS/src/perlmods/lib/OpenILS/WWW/OAI.pm)
 - [Open-ILS/src/perlmods/lib/OpenILS/Application/OAI.pm](Open-ILS/src/perlmods/lib/OpenILS/Application/OAI.pm)

Place them in your codebase next to the other openils modules and let them thus become part of the build:

    Open-ILS/src/perlmods/lib/OpenILS/Application/OAI.pm
    Open-ILS/src/perlmods/lib/OpenILS/WWW/OAI.pm

or copy the files (owned by the opensrf user) on your servers that host the openils services in the Perl library path:

    /the perl library path/OpenILS/Application/OAI.pm
    /the perl library path/OpenILS/WWW/OAI.pm

### 2.2 Declare the perl handler

Declare the Perl handler in the Apache eg_startup file:

```perl
use OpenILS::WWW::OAI qw( <openils sysdir>conf/opensrf_core.xml );
```
    
And reference it in the Apache eg_vhost.conf file:

```apache
<Location /opac/extras/oai>
    SetHandler perl-script
    PerlHandler OpenILS::WWW::OAI
    Options +ExecCGI
    PerlSendHeader On
    allow from all
</Location>
```
In the eg.conf file under 'PerlRequire /etc/apache2/eg_startup' add:
```apache
PerlChildInitHandler OpenILS::WWW::OAI::child_init

```

### 2.3 The database and fieldmapper

#### 2.3.1 Database

The service requires a view and stored procedures: [Open-ILS/src/sql/Pg/999.seed.iish.sql](Open-ILS/src/sql/Pg/999.seed.iish.sql#L156)

Add the oai section to the database:
```sql
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
```

#### 2.3.2 Optional, setting the datestamp

If you want the OAI2 datestamp to reflect changes in assets as well, add the following triggers
 ```sql
 
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
 ```

#### 2.3.3 The fieldmapper

Proceed by declaring the views in the fm_IDL.xml file so, as the example shows here [Open-ILS/examples/fm_ILD.xml](Open-ILS/examples/fm_IDL.xml):

```xml
<class id="oai_biblio" controller="open-ils.cstore" oils_obj:fieldmapper="oai::biblio"
       oils_persist:readonly="true" reporter:core="false" reporter:label="OAI2 record list"
       oils_persist:tablename="oai.biblio">
    <fields>
        <field reporter:label="TCN Value\OAI identifier postfix" name="tcn" reporter:datatype="number"/>
        <field reporter:label="Last edit date\OAI datestamp" name="datestamp" reporter:datatype="timestamp"/>
        <field reporter:label="Is Deleted?" name="deleted" reporter:datatype="bool"/>
        <field reporter:label="Setspec" name="set_spec" oils_persist:virtual="true"/>
    </fields>
</class>
<class id="oai_authority" controller="open-ils.cstore" oils_obj:fieldmapper="oai::authority"
       oils_persist:readonly="true" reporter:core="false" reporter:label="OAI2 record list"
       oils_persist:tablename="oai.authority">
    <fields>
        <field reporter:label="TCN Value\OAI identifier postfix" name="tcn" reporter:datatype="number"/>
        <field reporter:label="Last edit date\OAI datestamp" name="datestamp" reporter:datatype="timestamp"/>
        <field reporter:label="Is Deleted?" name="deleted" reporter:datatype="bool"/>
        <field reporter:label="Setspec" name="set_spec" oils_persist:virtual="true"/>
    </fields>
</class>
```

### 2.4 The xslt stylesheets

Lookup the two documents here:

 - [Open-ILS/xsl/OAI2_OAIDC.xsl](Open-ILS/xsl/OAI2_OAIDC.xsl)
 - [Open-ILS/xsl/OAI2_MARC21slim.xsl](Open-ILS/xsl/OAI2_MARC21slim.xsl)

Place the stylesheets in your codebase next to the other xsl documents and let them thus become part of the build.
Or install them on your servers that host the openils services:

    /<openils sysdir>/var/xsl/OAI2_OAIDC.xsl
    /<openils sysdir>/var/xsl/OAI2_MARC21slim.xsl
    
### 2.5 Dependencies
The openils-oai service depends on a running openils-supercat service.
And the OAI2_OAIDC.xsl document uses the file [MARC21slim2OAIDC.xsl](Open-ILS/xsl/MARC21slim2OAIDC.xsl).
The service and stylesheet are part of the out-of-the-box Evergreen distributions.
        
But do install the ['HTTP::OAI' perl library from a CPAN repository](http://search.cpan.org/dist/HTTP-OAI/):

    $ cpan HTTP::OAI    
    

## 3. Configuration

### 3.1 Declare the service

Add the openils-oai service to your /&lt;openils sysdir&gt;/conf/opensrf.xml file.
```xml
....
<open-ils.oai>
    <keepalive>5</keepalive>
    <stateless>1</stateless>
    <language>perl</language>
    <implementation>OpenILS::Application::OAI</implementation>
    <max_requests>199</max_requests>
    <unix_config>
        <unix_sock>open-ils.oai_unix.sock</unix_sock>
        <unix_pid>open-ils.oai_unix.pid</unix_pid>
        <max_requests>1000</max_requests>
        <unix_log>open-ils.oai_unix.log</unix_log>
        <min_children>1</min_children>
        <max_children>5</max_children>
        <min_spare_children>1</min_spare_children>
        <max_spare_children>2</max_spare_children>
    </unix_config>
    <app_settings>

        <!-- Where necessary, override the default settings here in the app_settings element. -->

        <!-- The OAI endpoint. The domain is the name of your proxy or frontend opac website. -->
        <!-- <base_url>http://mydomain.org/opac/extras/oai</base_url> -->

        <!-- <repository_name>My organization(s)</repository_name> -->
        <!-- <admin_email>admin@mydomain.org</admin_email> -->

        <!-- The maximum number of records in a ListRecords and ListIdentifiers response. -->
        <!-- <max_count>50</max_count> -->

        <!-- <granularity>YYYY-MM-DDThh:mm:ss</granularity> -->
        <!-- <earliest_datestamp>0001-01-01</earliest_datestamp> -->
        <!-- <deleted_record>yes</deleted_record> -->
        <!-- <scheme>oai</scheme> -->
        <!-- <repository_identifier>mydomain.org</repository_identifier> -->
        <!-- <delimiter>:</delimiter> -->
        <!-- <sample_identifier>oai:mydomain.org:12345</sample_identifier> -->
        <!-- <list_sets>false</list_sets> -->

        <!--
        The metadataformat element contains the schema for the oai_dc and marcxml metadata formats.
        Each schema needs a reference to an xslt document.
        You can replace them with your custom xslt stylesheets.
        Place those in the /<openils sysdir>/var/xsl folder.
        You can also extend the OAI2 service further with new metadata schema.
        
        Bibliographic and authority records share the same stylesheet.
        Should you want to render them differently, use the
        marc:datafield[@tag='901']/marc:subfield[@code='t']
        value to identify the record type. -->

        <!--
        <metadataformat>
            <oai_dc>
                <namespace_uri>http://www.openarchives.org/OAI/2.0/oai_dc/</namespace_uri>
                <schema_location>http://www.openarchives.org/OAI/2.0/oai_dc.xsd</schema_location>
                <xslt>OAI2_OAIDC.xsl</xslt>
            </oai_dc>
            <marcxml>
                <namespace_uri>http://www.loc.gov/MARC21/slim</namespace_uri>
                <schema_location>http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd</schema_location>
                <xslt>OAI2_MARC21slim.xsl</xslt>
            </marcxml>
        </metadataformat> -->

        <!--
        You can add different schema to the metadataformat element thus:
            <mods>
                <namespace_uri>http://www.loc.gov/mods/</namespace_uri>
                <schema_location>http://www.loc.gov/standards/mods/mods.xsd</schema_location>
                <xslt>my-custom-marc2mods.xsl</xslt>
            </mods>
            <my-metadata_prefix>
                <namespace_uri>my-namespace_uri</namespace_uri>
                <schema_location>my-schema_location</schema_location>
                <xslt>my-marc2my-metadata.xsl</xslt>
            </my-metadata_prefix>
        -->

        <!-- Change the way the asset copy values are mapped to which subfield codes: -->
        <!--
        <copies>
            <a>location</a>
            <b>owning_lib</b>
            <c>callnumber</c>
            <d>circlib</d>
            <g>barcode</g>
            <n>status</n>
        </copies>
        -->
        <!-- Or add static values to the copies element like this:
            <z>A value that always should for example be in the 852$z</z>
        -->
        
        <!-- Accept only 852$[barcode] values that match this regular expression. E.g.
        <barcode_filter>^[A-Za-z0-9]+</barcode_filter>
        only renders 852 datafields that contain barcodes values that begin with letters and numbers. 
        <!--
        <barcode_filter><barcode_filter>
        -->
                
        <!-- Accept only 852$[status] values that match this regular expression. E.g.
        <status_filter>^Available$</status_filter>
        only renders 852 datafields that contain status code values that exactly match the string 'Available'. 
        <!--
        <status_filter></status_filter>
        -->

    </app_settings>
</open-ils.oai>
```

#### 3.2 Activate the service

Refer to the service in the opensrf.xml's activeapps element:
```xml
....
<activeapps>
    <appname>open-ils.oai</appname>
```

#### 3.3 Register the service with the router

Add the service to the public router with your /&lt;openils sysdir&gt;/conf/opensrf_core.xml
```xml
<config>
    <opensrf>
        <routers>
            <router>
                <name>router</name>
                <domain>public.realm</domain>
                <services>
                    <service>openils.oai</service>
                    ...
```
    





