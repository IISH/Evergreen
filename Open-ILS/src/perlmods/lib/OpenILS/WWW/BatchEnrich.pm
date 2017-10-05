# OpenILS::WWW::BatchUpdate provides CRUD operations for batch.schedule records.
#
# Copyright (c) 2014-2015  International Institute of Social History
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#
# Author: Lucien van Wouw <lwo@iisg.nl>

package OpenILS::WWW::BatchEnrich;
use strict;
use warnings;

use Apache2::Const -compile => qw(OK REDIRECT DECLINED NOT_FOUND :log);
use CGI;
use OpenSRF::EX qw(:try);
use OpenSRF::System;
use OpenSRF::AppSession;
use Encode;
use OpenSRF::Utils::Logger qw/$logger/;
use HTML::Entities;
use XML::LibXML;

# set the bootstrap config and template include directory when
# this module is loaded
my ($bootstrap, $_session_batch);

my %xslt_templates = (
    0 => {
        title => 'Titel, Land, Taal, call numbers en holdings'
    }
);

$xslt_templates{0}{xslt}=<<XSLT;
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:marc="http://www.loc.gov/MARC21/slim" exclude-result-prefixes="marc">

    <xsl:output omit-xml-declaration="yes" method="xml"/>

    <xsl:template match="node()|\@*">
        <xsl:apply-templates select="node()|\@*"/>
    </xsl:template>

    <xsl:template match="marc:record">

        <tr>

            <!-- Title (245ab) -->
            <td>
                <xsl:value-of select="marc:datafield[\@tag='245']/marc:subfield[\@code='a']"/>
                <xsl:value-of select="marc:datafield[\@tag='245']/marc:subfield[\@code='b']"/>
            </td>

            <!-- Organization (710ab) -->
            <td>
                <xsl:value-of select="marc:datafield[\@tag='710']/marc:subfield[\@code='a']"/>
                <xsl:value-of select="marc:datafield[\@tag='710']/marc:subfield[\@code='b']"/>
            </td>

            <!-- Ctry(008 pos 15-17 -->
            <td>
                <xsl:value-of select="substring(marc:controlfield[\@tag='008'], 16, 3)"/>
            </td>

            <!-- Lang(008 pos 18-20 -->
            <td>
                <xsl:value-of select="substring(marc:controlfield[\@tag='008'], 36, 3)"/>
            </td>

            <!-- Call Number(852j) with 866a -->
            <td>
                <table>
                    <xsl:for-each select="marc:datafield[\@tag='852']">
                        <xsl:if test="marc:subfield[\@code='j']">
                            <tr>
                                <td>
                                    <xsl:value-of select="marc:subfield[\@code='j']"/>
                                </td>
                                <td>
                                    <xsl:if test="following-sibling::node()/\@tag='866'">
                                        <xsl:value-of
                                                select="following-sibling::node()/marc:subfield[\@code='a']/text()"/>
                                    </xsl:if>
                                </td>
                            </tr>
                        </xsl:if>
                    </xsl:for-each>
                </table>
            </td>

        </tr>

    </xsl:template>


</xsl:stylesheet>
XSLT


#
sub import {
	my $self = shift;
	$bootstrap = shift;

	for my $xslt_key (keys %xslt_templates) {
        ${xslt_templates}{$xslt_key}{xslt} =~ s/\R/\\n/g ;
        ${xslt_templates}{$xslt_key}{xslt} =~ s/'/\\'/g ;
    }
}

#
sub child_init {
	OpenSRF::System->bootstrap_client( config_file => $bootstrap );
	Fieldmapper->import(IDL => OpenSRF::Utils::SettingsClient->new->config_value("IDL"));
	$_session_batch = OpenSRF::AppSession->create( 'open-ils.batch-enrich' );
	return Apache2::Const::OK;
}

#
sub handler {
	#
	my ($r) = @_;

	child_init() unless ($_session_batch);

	my $cgi = new CGI;

	my $auth_token = $cgi->cookie('ses') || $cgi->param('ses');
	my $auth = verify_login($auth_token);

	return Apache2::Const::DECLINED unless ($auth);

	# Assume we receive a simple GET with url patterns: /list or /edit/123 or /delete/123 or /update/123 ( with a POST something )
	my @parts = split('/', $cgi->path_info, 3 );
	my $method = $parts[1] unless (scalar @parts == 0);
	$method = 'list' unless ( $method );
	my $id = $parts[2] if (scalar @parts == 3);
	my %params = $cgi->Vars(); # all parameters: /list?orderBy=id ( retrieve with $params{orderBy}

	$r->content_type('text/html');
	$r->no_cache(1); # disable caching
	$r->print(<<'HTML');
<html xmlns="http://www.w3.org/1999/xhtml">

	<head>
		<title>Scheduled enrichment</title>

		<style type="text/css">
			@import '/js/dojo/dojo/resources/dojo.css';
			@import '/js/dojo/dijit/themes/tundra/tundra.css';
			.hide_me { display: none; visibility: hidden; }
		</style>

		<script type="text/javascript">
			var djConfig= {
				isDebug: false,
				parseOnLoad: true,
				AutoIDL: ['aou','aout','pgt','au','cbreb']
			}
		</script>

		<script src='/js/dojo/dojo/dojo.js'></script>

		<script type="text/javascript">

			dojo.require('openils.CGI');
			dojo.require('openils.XUL');
			dojo.require('openils.User');
			dojo.require('dojo.cookie');

			var cgi = new openils.CGI();
			var authtoken = dojo.cookie('ses') || cgi.param('ses');
			if (!authtoken && openils.XUL.isXUL()) {
				var stash = openils.XUL.getStash();
				authtoken = stash.session.key;
			}
			var u = new openils.User({ authtoken: authtoken });

		</script>
		<style type="text/css">
			table.batch {
				margin-top: 20px;
			}
			tr.batch {
			}
			td.batch, th.batch {
				border: 1px solid black;
				padding: 5px 5px 5px 5px;
				border-radius: 3px;
				empty-cells: show;
			}
			a.batch_button {
				display: inline-block;
				border: 1px solid black;
				border-radius: 3px;
				padding: 5px 15px 5px 15px;
				text-decoration: none;
				margin-top: 20px;
				margin-bottom: 10px;
				color: black;
			}
			a.batch_link {
				text-decoration: none;
				border-bottom: 1px dotted;
				color: black;
			}
			table.batch_show {
				margin-top: 20px;
			}
			tr.batch_show {
			}
			td.batch_show_label {
				color: grey;
				border: 1px solid grey;
				border-radius: 3px;
				padding: 5px 10px 5px 5px;
			}
			td.batch_show_value {
				color: black;
				border: 1px solid black;
				border-radius: 3px;
				padding: 5px 5px 5px 5px;
				empty-cells: show;
			}
			.batch_button_extra_margin_right {
				margin-right: 5px;
			}
			.batch_button_extra_margin_left {
				margin-left: 5px;
			}
			div.batch_error {
				color: red;
				font-weight: bold;
				margin-top: 20px;
			}
			.batch_textarea_xslt {
				font-size: 90%;
				width: 550px;
				height: 300px;
			}
			.batch_textarea_xml {
				font-size: 90%;
				width: 500px;
				height: 200px;
			}
			.batch_textarea_preview {
				font-size: 90%;
				width: 500px;
				height: 500px;
			}
		</style>
		<script type="text/javascript">
			function getXsltExample(i) {
				var originalValue = document.getElementById('fldXslt').value;

				if ( i != 0 && document.getElementById("fldXslt").value != '' ) {
//					var answer = confirm("The field XSLT already contains some data.\nWould you like to replace it with the example?\n")
//					if (answer == false ){
//						return false;
//					}
					document.getElementById('fldPreview').innerHTML="";
				}

				if ( i ==999 ) {
					document.getElementById('fldXslt').value=document.getElementById('fldXsltOriginal').value;
				}
HTML
				 for my $xslt_key (sort keys %xslt_templates) {
				    $r->print("else if ( i == $xslt_key ) {document.getElementById('fldXslt').value='$xslt_templates{$xslt_key}{xslt}';}");
				 }

$r->print(<<'HTML');
				if ( originalValue != document.getElementById('fldXslt').value ) {
					previewResult();
				}
			}

			function getXmlExample(i) {
				var originalValue = document.getElementById('fldXml').value;

				if ( i != 0 && document.getElementById("fldXml").value != '' ) {
//					var answer = confirm("The field XML already contains some data.\nWould you like to replace it with the example?\n")
//					if (answer == false ){
//						return false;
//					}
					document.getElementById('fldPreview').innerHTML="";
				}

				if ( i == 1 ) {
					document.getElementById('fldXml').value="<record xmlns=\"http://www.loc.gov/MARC21/slim\">\n<leader>00620nkm a22002170a 45 0</leader>\n<controlfield tag=\"001\">850725</controlfield>\n<controlfield tag=\"003\">NL-AMISG</controlfield>\n<controlfield tag=\"005\">19950210234845.0</controlfield>\n<controlfield tag=\"008\">199502suuuuuuuu||||||||||||||||||||||| d</controlfield>\n<datafield ind1=\" \" ind2=\" \" tag=\"035\">\n    <subfield codex=\"a\">(IISG)IISGb10604867</subfield>\n    <subfield code=\"a\">(IISG)IISGb10604867</subfield>\n    <subfield xcode=\"a\">(IISG)IISGb10604867</subfield>\n    <subfield code=\"b\">(IISG)IISGb10604867</subfield>\n    <subfield code=\"c\">(IISG)IISGb10604867</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\" \" tag=\"040\">\n    <subfield code=\"a\">NL-AmISG</subfield>\n</datafield>\n<datafield ind1=\"1\" ind2=\" \" tag=\"100\">\n    <subfield code=\"0\">(NL-AMISG)98787</subfield>\n    <subfield code=\"a\">D'Rozario, Rico,</subfield>\n    <subfield code=\"e\">photographer</subfield>\n</datafield>\n<datafield ind1=\"1\" ind2=\"0\" tag=\"245\">\n    <subfield code=\"k\">Visual document.</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\" \" tag=\"260\">\n    <subfield code=\"c\">1989, 18 september.</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\" \" tag=\"500\">\n    <subfield code=\"a\">Opening op Cruquiusweg 31. Van Alderwegen spreekt.</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\" \" tag=\"542\">\n    <subfield code=\"m\">closed</subfield>\n</datafield>\n<datafield ind1=\"1\" ind2=\"4\" tag=\"600\">\n    <subfield code=\"a\">Alderwegen, C.H. van.</subfield>\n    <subfield code=\"0\">(NL-AMISG)12073</subfield>\n</datafield>\n<datafield ind1=\"2\" ind2=\"4\" tag=\"610\">\n    <subfield code=\"a\">Internationaal Instituut voor Sociale Geschiedenis (Amsterdam)\n    </subfield>\n    <subfield code=\"0\">(NL-AMISG)164184</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\"4\" tag=\"648\">\n    <subfield code=\"a\">1989-1989.</subfield>\n    <subfield code=\"0\">(NL-AMISG)369907</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\"4\" tag=\"650\">\n    <subfield code=\"a\">Group portrait.</subfield>\n    <subfield code=\"0\">(NL-AMISG)112454</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\"4\" tag=\"651\">\n    <subfield code=\"a\">Amsterdam. (Netherlands)</subfield>\n    <subfield code=\"0\">(NL-AMISG)572941</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\"4\" tag=\"651\">\n    <subfield code=\"a\">International.</subfield>\n    <subfield code=\"0\">(NL-AMISG)144624</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\"4\" tag=\"655\">\n    <subfield code=\"a\">Photo.</subfield>\n    <subfield code=\"0\">(NL-AMISG)121213</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\" \" tag=\"695\">\n    <subfield code=\"a\">NED</subfield>\n    <subfield code=\"g\">Amsterdam.</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\" \" tag=\"695\">\n    <subfield code=\"a\">INT.</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\" \" tag=\"856\">\n    <subfield code=\"u\">http://hdl.handle.net/10622/30051000449956</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\" \" tag=\"902\">\n    <subfield code=\"a\">10622/44E997AA-418E-49D4-AEF8-AFA3216A1ABA</subfield>\n</datafield>\n<datafield ind1=\" \" ind2=\" \" tag=\"987\">\n    <subfield code=\"a\">T160/9</subfield>\n</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"901\">\n    <subfield code=\"a\">850725</subfield>\n    <subfield code=\"b\">Unknown</subfield>\n    <subfield code=\"c\">850725</subfield>\n    <subfield code=\"t\">biblio</subfield>\n    </datafield>\n</record>";
				}

				if ( originalValue != document.getElementById('fldXml').value ) {
					previewResult();
				}
			}
			function previewResult() {
				//
				var xml_field=document.getElementById("fldXml");
				var xslt_field=document.getElementById("fldXslt");

				document.getElementById("fldPreview").innerHTML = '';

				if ( xml_field.value == '' || xslt_field.value == '' ) {
					return false;
				}

				//
				var xml_value = xml_field.value;
				var xslt_value = xslt_field.value;

				//
				parser=new DOMParser();
				var xml = parser.parseFromString(xml_value, "text/xml");
				var xsl = parser.parseFromString(xslt_value, "text/xml");

				//
				var xsltProcessor = new XSLTProcessor();
				xsltProcessor.importStylesheet(xsl);
				resultDocument = xsltProcessor.transformToFragment(xml, document);

				//
				var result = (new XMLSerializer()).serializeToString(resultDocument);

				document.getElementById("fldPreview").innerHTML = result;

				return false;
			}
		</script>
	</head>

	<body style="margin:10px;" class='tundra'>
HTML

	my $response = action($auth_token, $method, $id, \%params);
	$r->print($response);

$r->print(<<'HTML');
	</body>
</html>
HTML

	return Apache2::Const::OK;
}

#
sub verify_login {
	#
	my ($auth_token) = @_;

	return undef unless $auth_token;

	my $auth = OpenSRF::AppSession
			->create("open-ils.auth")
			->request( "open-ils.auth.session.retrieve", $auth_token )
			->gather(1);

	if (ref($auth) eq 'HASH' && $auth->{ilsevent} == 1001) {
			return undef;
	}

	return $auth if ref($auth);
	return undef;
}

#
sub action {
	#
	my ($auth_token, $method, $id, $ref_params) = @_;

	return list($auth_token) if ( $method eq 'list');
	return add($ref_params) if ( $method eq 'add');
	return show($auth_token, $id) if ( $method eq 'show');
	return edit($auth_token, $id) if ( $method eq 'edit');
	return copy($auth_token, $id) if ( $method eq 'copy');
	return save($auth_token, $id) if ( $method eq 'save');
	return update($auth_token, $id) if ( $method eq 'update');
	return del($auth_token, $id) if ( $method eq 'delete');
	return harddel($auth_token, $id) if ( $method eq 'harddelete');

	die "Method $method not suported";
}

#
sub list {
	#
	my ($auth_token) = @_;

	my $cgi = new CGI;

	my $response = $_session_batch->request( 'open-ils.batch-enrich.schedule.list', $auth_token)->gather();
	my $addButton = "<a class=batch_button href=\"add\">Add new schedule</a>";

	my $html = "<h1>List</h1>";

	#
	$html .= $addButton . "
			<table class=batch>
			<tr class=batch>
				<th class=batch>#</th>
				<th class=batch>Title</th>
				<th class=batch>State</th>
				<th class=batch></th>
				<th class=batch>Result ( if successful )</th>
			</tr>
			";

	#
	for my $record (@$response) {
		my $o = Fieldmapper::batch::enrich->new($record);

		# if owner and not finished make url from title
		my $title = $o->title;
		if ( $o->status != 3 ) {
			$title = '<a class=batch_link href="show/' . $o->id . '">' . $title . '</a>';
		}

		# get state label
		my $state = getStateLabel($o->status);
		my $report_url = $o->report_url;

		#
		$html .= "
				<tr>
					<td class=batch>" . $o->id . "</td>
					<td class=batch>$title</td>
					<td class=batch><a href=\"${report_url}.enrich.log?ses=$auth_token\">$state</a></td>
					<td class=batch>
						<a class=batch_link href=\"show/" . $o->id . "\">Show</a> &nbsp;
						<a class=batch_link href=\"edit/" . $o->id . "\">Edit</a> &nbsp;
						<a class=batch_link href=\"copy/" . $o->id . "\">Copy</a>
					</td>
					<td class=batch><a href=\"${report_url}.html?ses=$auth_token\">${report_url}.html?ses=$auth_token</a></td>
				</tr>
				";
	}
#						<a class=batch_link href=\"delete/" . $o->id . "\">Soft delete</a> &nbsp;
#						<a class=batch_link href=\"harddelete/" . $o->id . "\">Hard delete</a> &nbsp;

	$html .= '</table>' . $addButton;

	return $html;
}

# SHOW ADD FORM
sub add {

    my $ref_params = shift;
    my %params = %{$ref_params};
    my $fldReportUrl = $params{url} || 'http://';

	#
	my $default_state = 0;
	my @allowed_states = allowed_states( $default_state );

	#
	my %data;
	# some default values on new record
	$data{fldEmail} = '@iisg.nl';
	$data{fldReportUrl} = $fldReportUrl;
	$data{fldXslt} = $xslt_templates{0}{xslt};
	#$data{fldXml} = "<record xmlns=\"http://www.loc.gov/MARC21/slim\">\n	<leader>00620nkm a22002170a 45 0</leader>\n	<controlfield tag=\"001\">850725</controlfield>\n	<controlfield tag=\"003\">NL-AMISG</controlfield>\n	<controlfield tag=\"005\">19950210234845.0</controlfield>\n	<controlfield tag=\"008\">199502suuuuuuuu||||||||||||||||||||||| d</controlfield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"035\">\n		<subfield code=\"a\">(IISG)IISGb10604867</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"040\">\n		<subfield code=\"a\">NL-AmISG</subfield>\n	</datafield>\n	<datafield ind1=\"1\" ind2=\" \" tag=\"100\">\n		<subfield code=\"0\">(NL-AMISG)98787</subfield>\n		<subfield code=\"a\">D'Rozario, Rico,</subfield>\n		<subfield code=\"e\">photographer</subfield>\n	</datafield>\n	<datafield ind1=\"1\" ind2=\"0\" tag=\"245\">\n		<subfield code=\"k\">Visual document.</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"260\">\n		<subfield code=\"c\">1989, 18 september.</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"500\">\n		<subfield code=\"a\">Opening op Cruquiusweg 31. Van Alderwegen spreekt.</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"542\">\n		<subfield code=\"m\">closed</subfield>\n	</datafield>\n	<datafield ind1=\"1\" ind2=\"4\" tag=\"600\">\n		<subfield code=\"a\">Alderwegen, C.H. van.</subfield>\n		<subfield code=\"0\">(NL-AMISG)12073</subfield>\n	</datafield>\n	<datafield ind1=\"2\" ind2=\"4\" tag=\"610\">\n		<subfield code=\"a\">Internationaal Instituut voor Sociale Geschiedenis (Amsterdam)\n		</subfield>\n		<subfield code=\"0\">(NL-AMISG)164184</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\"4\" tag=\"648\">\n		<subfield code=\"a\">1989-1989.</subfield>\n		<subfield code=\"0\">(NL-AMISG)369907</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\"4\" tag=\"650\">\n		<subfield code=\"a\">Group portrait.</subfield>\n		<subfield code=\"0\">(NL-AMISG)112454</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\"4\" tag=\"651\">\n		<subfield code=\"a\">Amsterdam. (Netherlands)</subfield>\n		<subfield code=\"0\">(NL-AMISG)572941</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\"4\" tag=\"651\">\n		<subfield code=\"a\">International.</subfield>\n		<subfield code=\"0\">(NL-AMISG)144624</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\"4\" tag=\"655\">\n		<subfield code=\"a\">Photo.</subfield>\n		<subfield code=\"0\">(NL-AMISG)121213</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"695\">\n		<subfield code=\"a\">NED</subfield>\n		<subfield code=\"g\">Amsterdam.</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"695\">\n		<subfield code=\"a\">INT.</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"856\">\n		<subfield code=\"u\">http://hdl.handle.net/10622/30051000449956</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"902\">\n		<subfield code=\"a\">10622/44E997AA-418E-49D4-AEF8-AFA3216A1ABA</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"987\">\n		<subfield code=\"a\">T160/9</subfield>\n	</datafield>\n	<datafield ind1=\" \" ind2=\" \" tag=\"901\">\n		<subfield code=\"a\">850725</subfield>\n		<subfield code=\"b\">Unknown</subfield>\n		<subfield code=\"c\">850725</subfield>\n		<subfield code=\"t\">biblio</subfield>\n	</datafield>\n</record>";

	#
	my $html = "<h1>Add</h1>";
	$html .= showEditForm(\%data, 0, \@allowed_states, $default_state, '');
	return $html;
}

# SHOW COPY FORM
sub copy {
	my ($auth_token, $id) = @_;

	#
	my $default_state = 0;
	my @allowed_states = allowed_states( $default_state );

	#
	my $response = $_session_batch->request( 'open-ils.batch-enrich.schedule.get', $auth_token, $id);
	my $object = Fieldmapper::batch::enrich->new($response->gather());

	#
	my %data;
	$data{fldTitle} = $object->title;
	$data{fldEmail} = $object->email;
	$data{fldReportUrl} = $object->report_url;
	$data{fldXslt} = $object->xslt;
	$data{fldRepeat} = $object->repeat;
	$data{fldState} = $default_state;

	#
	my $html = "<h1>Copy</h1>";
	$html .= showEditForm(\%data, 0, \@allowed_states, $default_state, '../');
	return $html;
}

# SHOW EDIT FORM
sub edit {
	my ($auth_token, $id) = @_;

	#
	my $response = $_session_batch->request( 'open-ils.batch-enrich.schedule.get', $auth_token, $id);
	my $object = Fieldmapper::batch::enrich->new($response->gather());

	#
	my %data;
	$data{fldId} = $object->id;
	$data{fldTitle} = $object->title;
	$data{fldEmail} = $object->email;
	$data{fldReportUrl} = $object->report_url;
	$data{fldXslt} = $object->xslt;
	$data{fldRepeat} = $object->repeat;
	$data{fldState} = $object->status;

	#
	my @allowed_states = allowed_states( $object->status );

	#
	my $html = "<h1>Edit</h1>";
	$html .= showEditForm(\%data, $object->id, \@allowed_states, $object->status, '../');
	return $html;
}

# SHOW PREVIEW
sub show {
	my ($auth_token, $id) = @_;

	#
	my $response = $_session_batch->request( 'open-ils.batch-enrich.schedule.get', $auth_token, $id);
	my $object = Fieldmapper::batch::enrich->new($response->gather());

	#
	my $fldId = $object->id;
	my $fldTitle = $object->title;
	my $fldRunner = $object->runner;
	my $fldStartTime = $object->start_time;
	my $fldCompleteTime = $object->complete_time;
	my $fldRunTime = $object->run_time;
	my $fldRepeat = $object->repeat;
	my $fldEmail = $object->email;
	my $fldReportUrl = $object->report_url;
	my $fldXslt = encode_entities($object->xslt);
	my $fldRecordsChanged = $object->records_changed;
	my $fldRecordsUnchanged = $object->records_unchanged;
	my $fldRecordsFailed = $object->records_failed;
	my $fldRecordsTotal = $object->records_total;
	my $fldState = $object->status;
	my $fldErrorCode = $object->error_code;
	my $fldErrorText = $object->error_text;

	# get state label
	my $stateLabel = getStateLabel($object->status);

	#
	my $form = '<h1>Show</h1>';
	$form .= "
		<table class=batch_show>
		<tr class=batch_show>
			<td class=batch_show_label>#:</td>
			<td class=batch_show_value>$fldId</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Title: *</td>
			<td class=batch_show_value>$fldTitle</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Runner:</td>
			<td class=batch_show_value>$fldRunner</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Start time:</td>
			<td class=batch_show_value>$fldStartTime</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Complete time:</td>
			<td class=batch_show_value>$fldCompleteTime</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Next run time:</td>
			<td class=batch_show_value>$fldRunTime</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Repeat every X days:</td>
			<td class=batch_show_value>$fldRepeat</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>E-mail:</td>
			<td class=batch_show_value>$fldEmail</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Report URL:</td>
			<td class=batch_show_value>$fldReportUrl</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Enriched Report URL:</td>
			<td class=batch_show_value><a href=\"$fldReportUrl.html?ses=$auth_token\">$fldReportUrl.html?ses=$auth_token</a></td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>XSLT:</td>
			<td class=batch_show_value>$fldXslt</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Records changed:</td>
			<td class=batch_show_value>$fldRecordsChanged</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Records unchanged:</td>
			<td class=batch_show_value>$fldRecordsUnchanged</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Records failed:</td>
			<td class=batch_show_value>$fldRecordsFailed</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Records total:</td>
			<td class=batch_show_value>$fldRecordsTotal</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>State:</td>
			<td class=batch_show_value><a href=\"${fldReportUrl}.enrich.log?ses=$auth_token\">$stateLabel</a></td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Error code:</td>
			<td class=batch_show_value>$fldErrorCode</td>
		</tr>
		<tr class=batch_show>
			<td class=batch_show_label>Error text:</td>
			<td class=batch_show_value>$fldErrorText</td>
		</tr>
		<tr class=batch_show>
			<td align=right><a class=\"batch_button batch_button_extra_margin_right\" href=\"../list\">Go back</a></td>
			<td><a class=\"batch_button batch_button_extra_margin_left\" href=\"../edit/" . $object->id . "\">Edit</a></td>
		</tr>
		</table>
		";

	#
	return $form;
}

sub showEditForm {
	#
	my ($data, $id, $allowed_states, $default_state, $path_to_parent_directory) = @_;
	my %datahash = %$data;

	#
	my $fldId = $datahash{fldId};
	my $fldTitle = $datahash{fldTitle};
	my $fldEmail = $datahash{fldEmail};
	my $fldReportUrl = $datahash{fldReportUrl};
	my $fldXslt = $datahash{fldXslt};
	my $fldXml = $datahash{fldXml};
	my $fldState = $datahash{fldState};
	my $fldError = $datahash{fldError};
	my $fldRepeat = $datahash{fldRepeat};

	#
	my $allowed_states_options = createStateOptions($default_state, \@$allowed_states);

	#
	my $action = 'save';
	if ( $id > 0 ) {
		$action = 'update/' . $id;
	}

	#
	$action = $path_to_parent_directory . $action;

	# create form
	my $form = '';

	$form .= "
<table width='100%'>
<tr>
	<td valign='top'>
";

	#
	if ( $fldError ) {
		$form .= "<div class='batch_error'>$fldError</div>";
	}

	$form .= "
		<form name='frmSchedule' action='$action' method='POST'>
			<table class='batch_show'>
			<tr class='batch_show'>
				<td class='batch_show_label'>#:</td>
				<td class='batch_show_value'>$fldId</td>
			</tr>
			<tr class='batch_show'>
				<td class='batch_show_label'>Title: *</td>
				<td class='batch_show_value'><input name=\"fldTitle\" value=\"$fldTitle\" size=80 maxlength=255 placeholder=\"\"></td>
			</tr>
			<tr class='batch_show'>
				<td class='batch_show_label'>E-mail: *</td>
				<td class='batch_show_value'><input name=\"fldEmail\" value=\"$fldEmail\" size=80 maxlength=255 placeholder=\"example&#64;iisg.nl\"></td>
			</tr>
			<tr class='batch_show'>
				<td class='batch_show_label'>Report URL: *</td>
				<td class='batch_show_value'><input name=\"fldReportUrl\" value=\"$fldReportUrl\" size=80 maxlength=255 placeholder=\"http://www.iisg.nl/example\"></td>
			</tr>
			<tr class='batch_show'>
				<td class='batch_show_label'>Repeat every X days:</td>
				<td class='batch_show_value'><input name=\"fldRepeat\" value=\"$fldRepeat\" size=\"10\" maxlength=\"3\" ></td>
			</tr>
			<tr class='batch_show'>
				<td class='batch_show_label' valign='top' style='white-space: nowrap;'>XSLT: *<br/>";
    my $i = 0;
    for my $xslt_key (sort keys %xslt_templates) {
        my $checked = ( $i++ == 0 ) ? 'checked' : "";
        $form .="<input type='radio' name='fldXsltExample' onchange='getXsltExample($xslt_key);' $checked> $xslt_templates{$xslt_key}{title}<br/>";
    }
				$form .="</td>
				<td class='batch_show_value'>
					<textarea name='fldXslt' id='fldXslt' class='batch_textarea_xslt' onkeyup='previewResult();'>$fldXslt</textarea>
					<div style='display:none;'><textarea name='fldXsltOriginal' id='fldXsltOriginal' class='batch_textarea_xslt'>$fldXslt</textarea></div>
				</td>
			</tr>
			<tr class='batch_show'>
				<td class='batch_show_label'>State:</td>
				<td class='batch_show_value'><select name='fldState'>$allowed_states_options</select></td>
			</tr>
			<tr class='batch_show'>
				<td align=right><a class='batch_button batch_button_extra_margin_right' href=\"" . $path_to_parent_directory . "list\">Cancel</a></td>
				<td><a class='batch_button batch_button_extra_margin_left' href='#' onClick='javascript:document.frmSchedule.submit();return false;'>Save</a></td>
			</tr>
			</table>
		";
# &nbsp; <a class='batch_button batch_button_extra_margin_left' href='#' onClick='previewResult();return false;'>Preview</a>

	# middle table
	$form .= "
</td>
<td width='50%' valign='top'>
";

	# preview part
	$form .= "
			<table class='batch_show'>

			<tr class='batch_show'>
				<td valign='top' class='batch_show_value'>
					<b>XML Example</b> &nbsp; <select onchange='getXmlExample(this.value);'>
						<option value=\"0\"></option>
						<option value=\"1\">example 1</option>
					</select><br>
					<textarea name='fldXml' id='fldXml' class='batch_textarea_xml' onkeyup='previewResult();'>$fldXml</textarea>
					<br>
					<br>
					<b>Preview</b><br>
					<textarea name='fldPreview' id='fldPreview' class='batch_textarea_preview'></textarea>
				</td>
			</tr>

			</table>
	";

	# end table
	$form .= "
		</form>
	</td>
</tr>
</table>
";

	return $form;
}

# SAVE NEW RECORD
sub save {
	#
	my ($auth_token, $id) = @_;

	my $cgi = new CGI;

	#
	my $default_state = 0;
	my @allowed_states = allowed_states( $default_state );

	# get POST values
	my %data = getPostData($id);

	# check if post command
	if ( 'POST' eq $cgi->request_method ) {

		# check all required fields
		$data{fldError} = checkPostData(\%data);

		#
		if ( $data{fldError} ne "" ) {
			#
			my $form = '<h1>Save</h1>';
			$form .= showEditForm(\%data, $id, \@allowed_states, $data{fldState}, '');
			return $form;
		} else {
			# save document
			my $newId = saveNewDocument($auth_token, \%data);

			#
			return "Document saved as #$newId.<br>Go to <a class='batch_button' href=\"list\">list</a>";
		}
	}
}

# get post data
sub getPostData {
	my ($id) = @_;

	my $cgi = new CGI;
	my %data;

	# get POST values
	if ( 'POST' eq $cgi->request_method ) {
		$data{fldId} = $id;
		$data{fldTitle} = $cgi->param('fldTitle');
		$data{fldEmail} = $cgi->param('fldXslt');
		$data{fldReportUrl} = $cgi->param('fldReportUrl');
		$data{fldRepeat} = $cgi->param('fldRepeat');
		$data{fldXslt} = $cgi->param('fldXslt');
		$data{fldXml} = $cgi->param('fldXml');
		$data{fldState} = $cgi->param('fldState');
		$data{fldEmail} = $cgi->param('fldEmail');
	}

	return %data;
}

#
sub allowed_states {
	my ($current_state) = @_;

	my @allowedStates;

	push(@allowedStates, $current_state);

	if ( $current_state == 0 ) {
		# new
		push(@allowedStates, 1);
	}
	if ( $current_state == 1 ) {
		# in queue waiting
		push(@allowedStates, 0);
		push(@allowedStates, 9);
	}
	if ( $current_state == 2 ) {
		# running
		push(@allowedStates, 5);
		push(@allowedStates, 9);
	}
	if ( $current_state == 3 ) {
		# finished
		push(@allowedStates, 0);
		push(@allowedStates, 1);
        push(@allowedStates, 9);
	}
	if ( $current_state == 4 ) {
		# error
		push(@allowedStates, 1);
	}
	if ( $current_state == 5 ) {
		# cancelled
		push(@allowedStates, 1);
		push(@allowedStates, 9);
	}
	if ( $current_state == 9 ) {
		# deleted
		push(@allowedStates, 1);
	}

	@allowedStates = sort @allowedStates;

	return @allowedStates;
}

# save new document
sub saveNewDocument {
	my ($auth_token, $data) = @_;
	my %datahash = %$data;

	# create document
	my $o0 = Fieldmapper::batch::enrich->new;
	$o0->title( $datahash{fldTitle} );
	$o0->xslt( $datahash{fldXslt} );
	$o0->report_url( $datahash{fldReportUrl} );
	$o0->email( $datahash{fldEmail} );
	$o0->status( $datahash{fldState} );
	$o0->repeat( $datahash{fldRepeat} );

	# save new document
	my $response = $_session_batch->request( 'open-ils.batch-enrich.schedule.insert', $auth_token, $o0);
	my $newObject = Fieldmapper::batch::enrich->new($response->gather());

	# return new id
	return $newObject->id;
}

# UPDATE EXISTING RECORD
sub update {
	#
	my ($auth_token, $id) = @_;

	my $cgi = new CGI;

	# get POST values
	my %data = getPostData($id);

	# check if post command
	if ( 'POST' eq $cgi->request_method ) {

		# check all required fields
		$data{fldError} = checkPostData(\%data);

		if ( $data{fldError} ne "" ) {
			#
			my @allowed_states = allowed_states( $data{fldState} );

			#
			return showEditForm(\%data, $id, \@allowed_states, $data{fldState}, '../');
		} else {
			# save document
			saveExistingDocument($auth_token, $id, \%data);

			#
			return "Document #$id has been saved.<br>Go to <a class='batch_button' href=\"../list\">list</a>";
		}
	}
}

sub saveExistingDocument {
	my ($auth_token, $id, $data) = @_;
	my %datahash = %$data;

	#
	my $response = $_session_batch->request( 'open-ils.batch-enrich.schedule.get', $auth_token, $id);
	my $o2 = Fieldmapper::batch::enrich->new($response->gather());

	#
	$o2->title( $datahash{fldTitle} );
	$o2->xslt( $datahash{fldXslt} );
	$o2->report_url( $datahash{fldReportUrl} );
	$o2->email( $datahash{fldEmail} );
	$o2->status( $datahash{fldState} );
	$o2->repeat( $datahash{fldRepeat} );

	#
	my $response2 = $_session_batch->request( 'open-ils.batch-enrich.schedule.update', $auth_token, $o2);
}

# SOFT DELETE RECORD
sub del {
	#
	my ($auth_token, $id) = @_;

	#
	my $response = $_session_batch->request( 'open-ils.batch-enrich.schedule.get', $auth_token, $id);
	my $o2 = Fieldmapper::batch::enrich->new($response->gather());

	#
	$o2->status(9);

	#
	my $response2 = $_session_batch->request( 'open-ils.batch-enrich.schedule.update', $auth_token, $o2);

	#
	return "Document #" . $o2->id . " has been (soft) deleted.<br>Go to <a class='batch_button' href=\"../list\">list</a>";
}

# HARD DELETE RECORD
sub harddel {
	#
	my ($auth_token, $id) = @_;

	#
	my $response = $_session_batch->request( 'open-ils.batch-enrich.schedule.delete', $auth_token, $id);

	#
	return "Document #$id has been (hard) deleted.<br>Go to <a class='batch_button' href=\"../list\">list</a>";
}

# get state label
sub getStateLabel {
	#
	my ($state) = @_;

	#
	my @states;
	$states[0] = 'new';
	$states[1] = 'in queue';
	$states[2] = 'running';
	$states[3] = 'finished';
	$states[4] = 'error';
	$states[5] = 'cancelled';
	$states[9] = 'deleted';

	#
	return $states[$state];
}

# create html string of all options
sub createStateOptions {
	#
	my ($current_state, $possible_states) = @_;

	#
	my $options = '';
	my $selected;
	for ( @$possible_states ) {
		#
		if ( $_ == $current_state ) {
			$selected = 'SELECTED';
		} else {
			$selected = '';
		}

		#
		my $value = $_;
		my $label = getStateLabel($_);

		#
		$options .= "<option value='$value' $selected >$label</option>";
	}

	#
	return $options;
}

#
sub isValidEmail {
	#
	my ($email) = @_;

	$email = trim($email);

	if ($email ne "")
	{
		if ($email !~ /^.+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z0-9]+)(\]?)+$/) {
			return 0;
		} else {
			return 1;
		}
	}

	return 1;
}

#
sub isValidPositiveInteger {
	#
	my ($integer) = @_;

	$integer = trim($integer);

	if ($integer ne "")
	{
		if ($integer !~ /^[0-9]+$/) {
			return 0;
		} else {
			return 1;
		}
	}

	return 1;
}

# simple url validator
sub isValidUrl {
	#
	my ($url) = @_;

	$url = trim($url);
	$url = lc($url);

	if ($url ne "")
	{
		if ($url !~ /^https?\:\/\/.+\..+(\/.*)*$/) {
			return 0;
		} else {
			return 1;
		}

	}

	return 1;
}

#
sub trim {
	my ($s) = @_;

	$s =~ s/^\s+|\s+$//g;
	return $s;
}

#
sub checkPostData {
	my ($data) = @_;
	my %datahash = %$data;

	my $error_text = '';
	my $separator = '';

	# check title
	if ( $datahash{fldTitle} eq "" ) {
		$error_text .= $separator . 'Title is required.';
		$separator = '<br>';
	}

	# check email
	if ( $datahash{fldEmail} eq "" ) {
		$error_text .= $separator . 'E-mail is required.';
		$separator = '<br>';
	} else {
		if ( isValidEmail($datahash{fldEmail}) == 0 ) {
			$error_text .= $separator . 'E-mail is not valid.';
			$separator = '<br>';
		}
	}

	# check report url
	if ( $datahash{fldReportUrl} eq "" ) {
		$error_text .= $separator . 'Report URL is required.';
		$separator = '<br>';
	} else {
		if ( isValidUrl($datahash{fldReportUrl}) == 0 ) {
			$error_text .= $separator . 'Report URL is not valid.';
			$separator = '<br>';
		}
	}

	# check repeat
	if ( $datahash{fldRepeat} ne "" ) {
		if ( isValidPositiveInteger($datahash{fldRepeat}) == 0 ) {
			$error_text .= $separator . 'Repeat every X days is not a valid positive integer or zero or empty.';
			$separator = '<br>';
		}
	}

	# check xslt
	if ( $datahash{fldXslt} eq "" ) {
		$error_text .= $separator . 'XSLT is required.';
		$separator = '<br>';
	} else {
		my $parser = XML::LibXML->new();
		my $xml_text = eval { $parser->parse_string( $datahash{fldXslt} ); };
		if ( $@ ne "" ) {
			$error_text .= $separator . 'XSLT is not valid. error: ' . $@;
			$separator = '<br>';
		}
	}

	return $error_text;
}

1;
