#!/usr/bin/perl
#
# batman.pl provides batch update operations.
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
#
#
# This script will take all scheduled batch records from a table. For each batch the specified reports is loaded and it's tcns collected.
# An xslt transformation is applied to each bibliographic marc field. If different from the original, it will be stored.
# Only one batch process is allowed to run at any one time. It will not spawn multiple threats.
#
# I am not sure how to deploy this within the make distribution.... so I placed it under the support scripts.

use strict;
use warnings;
use DBI;
use FileHandle;
use Getopt::Long;
use OpenSRF::EX qw/:try/;
use OpenSRF::Utils::JSON;
use OpenSRF::Utils qw/:daemon/;
use OpenSRF::Utils::Logger qw/$logger/;
use OpenSRF::System;
use OpenSRF::AppSession;
use OpenSRF::Utils::SettingsClient;
use Email::Send;
use OpenILS::Application::AppUtils;
use Text::CSV ;
use Scalar::Util qw(looks_like_number);
use FindBin;
use FindBin qw($Bin);


use open ':utf8';

my $U = "OpenILS::Application::AppUtils";
use XML::LibXML;
use XML::LibXSLT;

#
# Instantiate the XML and XSLT packages
my $_xml_parser = new XML::LibXML;
my $_xslt_parser = new XML::LibXSLT;


#
# The fingerprint is used for comparing the source and end result of the transformation
my $xslt_fingerprint = $_xslt_parser->parse_stylesheet($_xml_parser->parse_string(<<'XSLT'));
<xsl:stylesheet version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns="http://www.loc.gov/MARC21/slim"
               xmlns:marc="http://www.loc.gov/MARC21/slim"
       exclude-result-prefixes="marc">
   <xsl:output omit-xml-declaration="yes" indent="no"/>

   <xsl:template match="marc:record">
           <xsl:value-of select="concat('\\leader', marc:leader)"/>
           <xsl:for-each select="marc:controlfield">
               <xsl:value-of select="concat('\\', @tag, '  ', text())"/>
           </xsl:for-each>
           <xsl:for-each select="marc:datafield">
               <xsl:value-of select="concat('\\', @tag, @ind1, @ind2)"/>
               <xsl:for-each select="marc:subfield">
                   <xsl:value-of select="concat('$', @code, text())"/>
               </xsl:for-each>
           </xsl:for-each>
   </xsl:template>

</xsl:stylesheet>
XSLT

# A dummy marc record for trying out the transformation with.
my $dummy_marc = <<'XML';
<record xmlns="http://www.loc.gov/MARC21/slim">
    <leader>01142cam  2200301 a 4500</leader>
    <controlfield tag="001">   92005291 </controlfield>
    <controlfield tag="003">DLC</controlfield>
    <controlfield tag="005">19930521155141.9</controlfield>
    <controlfield tag="008">920219s1993    caua   j      000 0 eng  </controlfield>
    <datafield tag="010" ind1=" " ind2=" ">
        <subfield code="a">   92005291 </subfield>
    </datafield>
    <datafield tag="020" ind1=" " ind2=" ">
        <subfield code="a">0152038655 :</subfield>
        <subfield code="c">$15.95</subfield>
    </datafield>
    <datafield tag="040" ind1=" " ind2=" ">
        <subfield code="a">DLC</subfield>
        <subfield code="c">DLC</subfield>
        <subfield code="d">DLC</subfield>
    </datafield>
    <datafield tag="042" ind1=" " ind2=" ">
        <subfield code="a">lcac</subfield>
    </datafield>
    <datafield tag="050" ind1="0" ind2="0">
        <subfield code="a">PS3537.A618</subfield>
        <subfield code="b">A88 1993</subfield>
    </datafield>
    <datafield tag="082" ind1="0" ind2="0">
        <subfield code="a">811/.52</subfield>
        <subfield code="2">20</subfield>
    </datafield>
    <datafield tag="100" ind1="1" ind2=" ">
        <subfield code="a">Sandburg, Carl,</subfield>
        <subfield code="d">1878-1967.</subfield>
    </datafield>
    <datafield tag="245" ind1="1" ind2="0">
        <subfield code="a">Arithmetic /</subfield>
        <subfield code="c">Carl Sandburg ; illustrated as an anamorphic adventure by Ted Rand.</subfield>
    </datafield>
    <datafield tag="250" ind1=" " ind2=" ">
        <subfield code="a">1st ed.</subfield>
    </datafield>
    <datafield tag="260" ind1=" " ind2=" ">
        <subfield code="a">San Diego :</subfield>
        <subfield code="b">Harcourt Brace Jovanovich,</subfield>
        <subfield code="c">c1993.</subfield>
    </datafield>
    <datafield tag="300" ind1=" " ind2=" ">
        <subfield code="a">1 v. (unpaged) :</subfield>
        <subfield code="b">ill. (some col.) ;</subfield>
        <subfield code="c">26 cm.</subfield>
    </datafield>
    <datafield tag="500" ind1=" " ind2=" ">
        <subfield code="a">One Mylar sheet included in pocket.</subfield>
    </datafield>
    <datafield tag="520" ind1=" " ind2=" ">
        <subfield code="a">A poem about numbers and their characteristics. Features anamorphic, or distorted, drawings which can be restored to normal by viewing from a particular angle or by viewing the image's reflection in the provided Mylar cone.</subfield>
    </datafield>
    <datafield tag="650" ind1=" " ind2="0">
        <subfield code="a">Arithmetic</subfield>
        <subfield code="x">Juvenile poetry.</subfield>
    </datafield>
    <datafield tag="650" ind1=" " ind2="0">
        <subfield code="a">Children's poetry, American.</subfield>
    </datafield>
    <datafield tag="650" ind1=" " ind2="1">
        <subfield code="a">Arithmetic</subfield>
        <subfield code="x">Poetry.</subfield>
    </datafield>
    <datafield tag="650" ind1=" " ind2="1">
        <subfield code="a">American poetry.</subfield>
    </datafield>
    <datafield tag="650" ind1=" " ind2="1">
        <subfield code="a">Visual perception.</subfield>
    </datafield>
    <datafield tag="700" ind1="1" ind2=" ">
        <subfield code="a">Rand, Ted,</subfield>
        <subfield code="e">ill.</subfield>
    </datafield>
</record>
XML


#
# Schema validator for our marc
my $xmlschema = XML::LibXML::Schema->new( location => $Bin . '/marc21slim.xsd' );


#
# Pause in seconds between checking for new batch tasks
my $UPDATE_STATUS_INTERVAL = 10;


#
# Number of minutes a heartbeat is set from now. This is used to detect stale batch tasks
my $HEARTBEAT_INTERVAL = 5;


#
# Load settings
my ($count, $config, $sleep_interval, $lockfile, $daemon) = (1, '/openils/conf/opensrf_core.xml', 10, '/tmp/batch-LOCK');

GetOptions(
	"daemon"	=> \$daemon,
	"sleep=i"	=> \$sleep_interval,
	"bootstrap=s"	=> \$config,
	"lockfile=s"	=> \$lockfile,
);

if (-e $lockfile) {
	die "I seem to be running already. If not, remove $lockfile and try again\n";
}

OpenSRF::System->bootstrap_client( config_file => $config );

my %data_db;

my $sc = OpenSRF::Utils::SettingsClient->new;

$data_db{db_driver} = $sc->config_value( apps => 'open-ils.storage' => app_settings => databases => 'driver' );
$data_db{db_host}   = $sc->config_value( apps => 'open-ils.storage' => app_settings => databases => database => 'host' );
$data_db{db_port}   = $sc->config_value( apps => 'open-ils.storage' => app_settings => databases => database => 'port' );
$data_db{db_name}   = $sc->config_value( apps => 'open-ils.storage' => app_settings => databases => database => 'db' );
$data_db{db_user}   = $sc->config_value( apps => 'open-ils.storage' => app_settings => databases => database => 'user' );
$data_db{db_pw}     = $sc->config_value( apps => 'open-ils.storage' => app_settings => databases => database => 'pw' );

die "Unable to retrieve database connection information from the settings server"
    unless ( $data_db{db_driver} && $data_db{db_host} && $data_db{db_port} && $data_db{db_name} && $data_db{db_user});

my $email_server     = $sc->config_value( email_notify => 'smtp_server' );
my $email_sender     = $sc->config_value( email_notify => 'sender_address' );
my $success_template = $Bin . '/batman-success';
my $fail_template    = $Bin . '/batman-fail';
my $base_uri         = $sc->config_value( reporter => setup => 'base_uri' );
my $output_base      = $sc->config_value( reporter => setup => files => 'output_base' );

my $data_dsn  = "dbi:" .  $data_db{db_driver} . ":dbname=" .  $data_db{db_name} .';host=' .  $data_db{db_host} . ';port=' .  $data_db{db_port};

my ($dbh, $running, $sth, @reports, $run);

sub message {
    my @messages = (
	    "Mr. Freeze, give yourself up. We can get help for you... medical help!",
        "Why is a woman in love like a welder? Because they both carry a torch!",
        "No use, Joker! I knew you'd employ your sneezing powder, so I took an Anti-Allergy Pill! Instead of a SNEEZE, I've caught YOU, COLD!'",
        "It's Alfred's emergency belt-buckle Bat-call signal! He's in trouble!'",
        "I never touch spirits. Have you some milk?'",
        "Come on, Robin, to the Bat Cave! There's not a moment to lose!'",
        "It was noble of that animal to hurl himself into the path of that final torpedo. He gave his life for ours'",
        "An older head can't be put on younger shoulders.'",
        "Stop fiddling with that atomic pile and come down here!'",
        "Careful, Robin. Both hands on the Bat-rope.'",
        "Remember Robin, always look both ways.'",
        "Of course, Robin. Even crime-fighters must eat. And especially you. You're a growing boy and you need your nutrition.'",
        "Better three hours too soon than a minute too late.'",
        "It's sometimes difficult to think clearly when you're strapped to a printing press.'",
        "This is torture, at its most bizarre and terrible.'",
        "If you can't spend it, money's just a lot of worthless paper, isn't it?'",
        "Since there is no life on Mars as we know it, there can be no intelligible Marsish language.'",
        "Whatever is fair in love and war is also fair in crime fighting.'",
        "Planting a time bomb in a local library is a felony.'",
        "Ka-Pow !"
    ) ;

    my $message = $messages[rand @messages] ;
    $logger->info($message);
    return 'Batman: "' . $message . '"';
}


#
# Create fork if needed
if ($daemon) {
	open(F, ">$lockfile") or die "Cannot write lockfile '$lockfile'";
	print F $$;
	close F;
	daemonize(message());
}


#
# From here on loop:
DAEMON:

$dbh = DBI->connect(
	$data_dsn,
	$data_db{db_user},
	$data_db{db_pw},
	{ AutoCommit => 1,
	  pg_expand_array => 0,
	  pg_enable_utf8 => 1,
	  RaiseError => 1
	}
);


# Cancel any orphaned tasks where status(2)=running with an expired heartbeat value
#
$dbh->do(<<'SQL');
        UPDATE batch.schedule SET
            start_time = NULL,
            heartbeat_time = NULL,
            status = 4,
            error_code = 1,
            error_text = 'The heartbeat expired. Maybe the server or batch daemon restarted ? Re-queue this record to try again.'
        WHERE
            status = 2 AND heartbeat_time < now();
SQL


#
# make sure we're not already running $count reports
# status(2) = actively running
($running) = $dbh->selectrow_array(<<'SQL');
SELECT	count(*)
  FROM	batch.schedule
  WHERE	status = 2;
SQL

if ($count <= $running) {
    if ($daemon) {
    		$dbh->disconnect;
    		sleep 1;
    		POSIX::waitpid( -1, POSIX::WNOHANG );
    		sleep $sleep_interval;
    		goto DAEMON;
    }
    log_it("Already running maximum ($running) concurrent batches");
    exit 1;
}


#
# Number of slots.
# We'll pick one from the list. We will not use the open slot $run variable.
$run = $count - $running;
log_it("Available candidates: " . $run) ;
my $r = $dbh->selectrow_hashref(<<'SQL', {}, 1);
SELECT
    *
FROM
	batch.schedule
  WHERE
    status = 1 AND run_time < now()
  ORDER BY
    run_time
  LIMIT ?;
SQL

my ($id, $runner, $report_url, $xslt, $repeat, $email);
if ( $r ) {
    $id = $r->{id} ;
    $runner = $r->{runner};
    $report_url = $r->{report_url};
    $xslt = $r->{xslt};
    $repeat = $r->{repeat};
    $email = $r->{email};
} else {
    sleep 1;
    POSIX::waitpid( -1, POSIX::WNOHANG );
    sleep $sleep_interval;
    goto DAEMON if ($daemon);
    exit 0 ;
}


if (safe_fork()) {
    # Wait and retry.
} else {

    # Spawn a child
    daemonize(message());

    # Open database connection for this child.
    $logger->info("Running a batch for $id");
    my $data_dbh = DBI->connect(
        $data_dsn,
        $data_db{db_user},
        $data_db{db_pw},
        { AutoCommit => 1,
          pg_expand_array => 0,
          pg_enable_utf8 => 1,
          RaiseError => 1
        }
    );


    # set start_time and status
    $data_dbh->do(<<'SQL',{}, $HEARTBEAT_INTERVAL, $id);
        UPDATE
            batch.schedule
        SET
            start_time = now(),
            status = 2,
            records_changed = 0,
            records_unchanged = 0,
            records_failed = 0,
            records_total = 0,
            heartbeat_time = now() + (? * interval '1 minute'),
            error_code = 0,
            error_text = NULL
        WHERE
            id = ?;
SQL

    # Get the file from the last four parts of the url: https://a/b/c/d/e/1/2/report-data.csv
    unless ( $report_url =~ m/(\/\d*\/\d*\/\d*\/.*\.csv$)/ ) {
        my $e = 'Parsing url failed. I expect something that ends with /number/number/number/report-data.csv but I got ' . $report_url;
        error_exit($e, $id, $data_dbh, $email, $report_url);
    }
    my $file = $output_base . $1;
    unless ( -f $file ) {
        my $e = 'No such file: ' . $file ;
        error_exit( $e, $id, $data_dbh, $email, $report_url );
    }


    # Start logging to a file
    my $fh_debug = new FileHandle (">$file.batch.log") or die "Cannot write to '$file.batch.log'";
    log_it("Starting batch id(${id}) by runner(${runner}) for file(${file}) with xslt(${xslt})");


    # Load the xml into a stylesheet
    my $stylesheet;
    try {
        my $xml = $_xml_parser->parse_string( $xslt ) ;
        $stylesheet = $_xslt_parser->parse_stylesheet( $xml ) ;
    } otherwise {
        my $e = 'Parsing stylesheet failed. Correct the error and try again. The exception was ' . shift() ;
        error_exit($e, $id, $data_dbh, $email, $report_url, $fh_debug);
    };


    # Use a dummy ( but valid ) marc record to try out and see if the transformation is valid.
    try {
        my $new_marc = transform( $dummy_marc, $stylesheet ) ;
        $xmlschema->validate( $_xml_parser->parse_string($new_marc) );
    } otherwise {
        my $e = 'This stylesheet produces invalid XML or invalid MARC: ' . shift() ;
        error_exit($e, $id, $data_dbh, $email, $report_url, $fh_debug);
    };


    # Now open the report and for each line, find the tcn and store the value;
    my $csv = Text::CSV->new ({
      quote_char    => '"',
      sep_char      => ',',    # not really needed as this is the default
            binary => 1
    });

    my @tcns;
    open(my $data, '<:encoding(utf8)', $file) ;
    my $header = $csv->getline( $data ) ;
    my @array = @$header ;
    my ( $tcn_index ) = grep { $array[$_] eq 'TCN Value' } 0..$#array;
    $tcn_index = 0 unless ( $tcn_index ) ;
    while (my $fields = $csv->getline( $data )) {
        my $tcn = $fields->[$tcn_index] ;
        if ( looks_like_number( $tcn ) ) {
            unless ($tcn eq -1) {push @tcns, $tcn ;}
        } else {
            if ( $tcn ) { # We ignore blank, but everything else is a problem
                my $e = 'TCN value is not a number: ' . $tcn ;
                error_exit($e, $id, $data_dbh, $email, $report_url, $fh_debug);
            }
        }
    }
    if (not $csv->eof) {
        my $e = $csv->error_diag();
        error_exit($e, $id, $data_dbh, $email, $report_url, $fh_debug);
    }
    close $data;



    # Read in and parse each marc file
    my ($records_changed, $records_unchanged, $records_failed, $records_total) = (0, 0, 0, 0);
    foreach my $tcn (@tcns) {
        my $bre = $data_dbh->selectrow_hashref(<<'SQL', {}, $tcn);
            SELECT
                marc
            FROM
                biblio.record_entry
            WHERE
                id = ?
            LIMIT 1;
SQL


    # Apply the transformation and keep the before and after states
    my $marc = $bre->{marc} ;
    my $before = transform( $marc,     $xslt_fingerprint ) ;
    my $valid = 0; # invalid
    my $new_marc;
    try {
        $new_marc = transform( $marc,     $stylesheet ) ;
        $valid = 1;
    } otherwise {
        my $e = 'tcn(' . $tcn . '): There was an error whilst transforming the marc data. The exception was ' . shift() ;
        log_it($e, $fh_debug);
    };


    if ( $valid ) {
        # Validate the MarcXML
        try {
            $xmlschema->validate( $_xml_parser->parse_string($new_marc) );
        } otherwise {
            $valid = 0 ;
            my $e = 'tcn(' . $tcn . '): The new the marc data is not valid marc21 XML. The exception was ' . shift() ;
            log_it($e, $fh_debug);
            log_it('Rejected: ' . $new_marc, $fh_debug);
        };
    }


    # Update the marc record. SQL Insert...
    $records_total++;
    if ( $valid ) {
        my $after = transform( $new_marc, $xslt_fingerprint ) if ($new_marc) ;
        if ($before eq $after) {
            log_it("tcn ${tcn} : no change" );
            $records_unchanged++;
        } else {
            try {
                $data_dbh->do(<<'SQL',{}, $runner, $U->entityize($new_marc), $tcn);
                    UPDATE
                        biblio.record_entry
                    SET
                        edit_date = now(),
                        editor = ?,
                        marc = ?
                    WHERE
                        id = ?;
SQL
                log_it("tcn ${tcn} : updated" );
                $records_changed++;
            } otherwise {
                $records_failed++;
                my $e = 'tcn(' . $tcn . '): There was an error whilst saving the marc data into the database. The exception was ' . shift() ;
                log_it($e, $fh_debug);
            };
        }
    } else {
        $records_failed++;
    }


    # Give a heartbeat with status
    my $update_status = $records_total % $UPDATE_STATUS_INTERVAL ;
    if ( $update_status == 0 || $records_total == scalar @tcns) {
        $data_dbh->do(<<'SQL',{}, $records_changed, $records_unchanged, $records_failed, $records_total, $HEARTBEAT_INTERVAL, $id);
            UPDATE
                batch.schedule
            SET
                records_changed = ?,
                records_unchanged = ?,
                records_failed = ?,
                records_total = ?,
                heartbeat_time = now() + (? * interval '1 minute')
            WHERE
                id = ?;
SQL
        }

}


    #
    # Done work
    $repeat = 0 unless ($repeat) ;
    my $status = ($repeat) ? 1 :  3;
    $data_dbh->do(<<'SQL',{}, $status, $repeat, $id);
        UPDATE
            batch.schedule
        SET
        	complete_time = now(),
        	status = ?,
        	heartbeat_time = NULL,
        	run_time = now() + (? * interval '1 day')
        WHERE
            id = ?;
SQL

    log_it("records_changed = records_total=$records_total\nrecords_failed=$records_failed\n$records_changed\nrecords_unchanged=$records_unchanged\n");
    log_it('Done', $fh_debug) ;
    $data_dbh->disconnect;
    $fh_debug->close;

    notify($email, $report_url, $success_template);

    exit 0; # leave the child
}


if ($daemon) {
	sleep 1;
	POSIX::waitpid( -1, POSIX::WNOHANG );
	sleep $sleep_interval;
	goto DAEMON;
}

exit 0; # Exit as we are not a daemon

# parse the text into xml. Apply the stylesheet. Return the result without CrLfs.
sub transform {

    my $marc_text = shift ;
    my $stylesheet = shift ;

    my $marc_xml = $_xml_parser->parse_string( $marc_text ) ;
    my $result = $stylesheet->transform( $marc_xml );
    my $xml = $stylesheet->output_as_chars($result) ;
    $xml =~ s/\R//g;
    return $xml;
}


sub error_exit {

    my $error_text      = shift ;
    my $id              = shift ;
    my $dbh             = shift ;
    my $email           = shift ;
    my $report_url      = shift ;
    my $fh_debug        = shift ;

    log_it($error_text, $fh_debug) ;
    $dbh->do(<<'SQL',{}, $error_text, $id);
        UPDATE	batch.schedule
          SET status = 4,
            error_text = ?,
            error_code = 2,
            complete_time = now()
          WHERE id = ?;
SQL

    $dbh->disconnect;
    $fh_debug->close if ($fh_debug);

    notify($email, $report_url . 'batch.log', $fail_template);

    exit 1;
}

sub log_it {

    my $log = gmtime() . ' ' . shift ;
    my $fh_debug = shift ;

    print $fh_debug $log . "\n" if ($fh_debug);
    $logger->debug($log);
}

sub notify {
	my $email = shift;
	my $url = shift;
    my $template = shift ;

	return unless ( $email ) ;

	try {
	    open F, $template ;
	} otherwise {
	    my $e = shift ;
	    $logger->error($e);
	    return;
	};

	my $tmpl = join('',<F>);
	close F;

	$tmpl =~ s/{TO}/$email/smog;
	$tmpl =~ s/{FROM}/$email_sender/smog;
	$tmpl =~ s/{REPLY_TO}/$email_sender/smog;
	$tmpl =~ s/{OUTPUT_URL}/$url/smog;

	my $sender = Email::Send->new({mailer => 'SMTP'});
	$sender->mailer_args([Host => $email_server]);

	try {
	    $sender->send($tmpl);
	} otherwise {
        my $e = shift ;
        $logger->error($e);
    };
}






