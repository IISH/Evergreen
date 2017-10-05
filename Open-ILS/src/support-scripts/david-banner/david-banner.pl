#!/usr/bin/perl
#
# david-banner.pl provides report enrichment operations.
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
use LWP::UserAgent;


use open ':utf8';

my $U = "OpenILS::Application::AppUtils";
use XML::LibXML;
use XML::LibXSLT;

#
# Instantiate the XML and XSLT packages
my $_xml_parser = new XML::LibXML;
my $_xslt_parser = new XML::LibXSLT;



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
# Pause in seconds between checking for new batch tasks
my $UPDATE_STATUS_INTERVAL = 10;


#
# Number of minutes a heartbeat is set from now. This is used to detect stale batch tasks
my $HEARTBEAT_INTERVAL = 5;


#
# Load settings
my ($count, $config, $sleep_interval, $lockfile, $baseurl, $daemon) = (1, '/openils/conf/opensrf_core.xml', 10, '/tmp/enricher-LOCK', 'https://localhost/opac/extras/oai/biblio');

GetOptions(
	"daemon"	=> \$daemon,
	"sleep=i"	=> \$sleep_interval,
	"bootstrap=s"	=> \$config,
	"lockfile=s"	=> \$lockfile,
	"baseurl=s"	=> \$baseurl
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
my $success_template = $Bin . '/david-banner-success';
my $fail_template    = $Bin . '/david-banner-fail';
my $base_uri         = $sc->config_value( reporter => setup => 'base_uri' );
my $output_base      = $sc->config_value( reporter => setup => files => 'output_base' );

my $data_dsn  = "dbi:" .  $data_db{db_driver} . ":dbname=" .  $data_db{db_name} .';host=' .  $data_db{db_host} . ';port=' .  $data_db{db_port};

my ($dbh, $running, $sth, @reports, $run);

sub message {
    my @messages = (
	    "Mr. Mcgee don't make me angry; you wouldn't like me when I'm angry."
    ) ;

    my $message = $messages[rand @messages] ;
    $logger->info($message);
    return 'David Banner: "' . $message . '"';
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
        UPDATE batch.enrich SET
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
  FROM	batch.enrich
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
	batch.enrich
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
            batch.enrich
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
    my $fh_debug = new FileHandle (">$file.enrich.log") or die "Cannot write to '$file.batch.log'";
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


    # Open the new html report
    my $html_file = $file . '.html' ;
    open my $hf_html, '>:encoding(UTF-8)', $html_file or die "Cannot write to '$html_file'";
    print $hf_html '<html lang="en-US"><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8" /></head><body><table>';


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


    # Create our HTTP agent
    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    $ua->agent('Evergreen ILS david banner');


    # Read in and parse each marc file
    my ($records_changed, $records_unchanged, $records_failed, $records_total) = (0, 0, 0, 0);
    foreach my $tcn (@tcns) {
        my $url = $baseurl . '?verb=GetRecord&metadataPrefix=marcxml&identifier=oai:evergreen.iisg.nl:' . $tcn;
        my $bre = $ua->get( $url ) ;
        if (!$bre->is_success) {
            my $e = 'tcn(' . $tcn . '): There was an error calling ' . $url ;
            log_it($e, $fh_debug);
            next;
        }

    # Apply the transformation
    my $marc = $bre->content ;
    my $valid = 0; # invalid
    my $new_text;
    try {
        $new_text = transform( $marc,     $stylesheet ) ;
        $valid = 1;
    } otherwise {
        my $e = 'tcn(' . $tcn . '): There was an error whilst transforming the marc data. The exception was ' . shift() ;
        log_it($e, $fh_debug);
    };


    # Update the report with the new text
    $records_total++;
    if ( $valid ) {
        print $hf_html $new_text ;
        $records_changed++;
    } else {
        $records_failed++;
    }


    # Give a heartbeat with status
    my $update_status = $records_total % $UPDATE_STATUS_INTERVAL ;
    if ( $update_status == 0 || $records_total == scalar @tcns) {
        $data_dbh->do(<<'SQL',{}, $records_changed, $records_unchanged, $records_failed, $records_total, $HEARTBEAT_INTERVAL, $id);
            UPDATE
                batch.enrich
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
            batch.enrich
        SET
        	complete_time = now(),
        	status = ?,
        	heartbeat_time = NULL,
        	run_time = now() + (? * interval '1 day')
        WHERE
            id = ?;
SQL


    print $hf_html '</table></body></html>' ;
    $hf_html->close;

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
        UPDATE	batch.enrich
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






