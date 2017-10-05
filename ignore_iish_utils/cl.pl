#!/usr/bin/perl
use strict;
use warnings;

use lib '/openils/lib/perl5/';

use OpenSRF::System;
use OpenSRF::Application;
use OpenSRF::EX qw/:try/;
use OpenSRF::AppSession;
use OpenSRF::Utils::SettingsClient;
use OpenILS::Application::AppUtils;
use Digest::MD5 qw/md5_hex/;
use Getopt::Long;
use OpenILS::Utils::Fieldmapper;


my ($user, $password, $config) =
	('admin', 'admin', '/openils/conf/opensrf_core.xml');

GetOptions(
	'user=s'	=> \$user,
	'password=s'	=> \$password,
	'config=s'	=> \$config,
);

OpenSRF::System->bootstrap_client( config_file => $config );
Fieldmapper->import(IDL => OpenSRF::Utils::SettingsClient->new->config_value("IDL"));
use OpenILS::Utils::CStoreEditor;
OpenILS::Utils::CStoreEditor::init();


my $auth = login($user,$password);

sub login {
	my( $username, $password, $type ) = @_;

	$type |= "staff";

	my $seed = OpenILS::Application::AppUtils->simplereq(
		'open-ils.auth',
		'open-ils.auth.authenticate.init',
		$username
	);

	die("No auth seed. Couldn't talk to the auth server") unless $seed;

	my $response = OpenILS::Application::AppUtils->simplereq(
		'open-ils.auth',
		'open-ils.auth.authenticate.complete',
                {       username => $username,
                        password => md5_hex($seed . md5_hex($password)),
                        type => $type });

        die("No auth response returned on login.") unless $response;

        my $authtime = $response->{payload}->{authtime};
        my $authtoken = $response->{payload}->{authtoken};

	die("Login failed for user $username!") unless $authtoken;

        return $authtoken;
}

print "=========================== list =======================\n";
my $_session = OpenSRF::AppSession->create( 'open-ils.batch' );
my $response = $_session->request( 'open-ils.batch.schedule.list', $auth)->gather();

if ($response) {
        for my $record (@$response) {
	my $o = Fieldmapper::batch::schedule->new($record);	
               
		print $o->id . '. ' . 'title=' . $o->title . "\n";
        }
}
else {
        die 'No luck';
}


print "=========================== list with query  =======================\n";
my $query = {};
$query->{'id'} = {'>'=>40};
$response = $_session->request( 'open-ils.batch.schedule.list', $auth, $query)->gather();

if ($response) {
        for my $record (@$response) {
        my $o = Fieldmapper::batch::schedule->new($record);

                print $o->id . '. ' . 'title=' . $o->title . "\n";
        }
}
else {
        die 'No luck';
}



print "======================================== insert ====================\n";
my $o0 = Fieldmapper::batch::schedule->new;
$o0->title('my new title 12345');
$o0->xslt('<style sheet>');
$o0->runner(1);
$o0->report_url('report url');
$response = $_session->request( 'open-ils.batch.schedule.insert', $auth, $o0)->gather();
my $id = $response->id ;
print 'Result id = ' . $response->id . "\n";
print 'run_time=' . $response->run_time . "\n";

print "==================== get $id ===================\n" ;
$response = $_session->request( 'open-ils.batch.schedule.get', $auth, $id);
my $o2 = Fieldmapper::batch::schedule->new($response->gather());
print 'title=' .  $o2->title . "\n";
print 'run_time=' .  $o2->run_time . "\n";

$id = $o2->id ;
print "==================== update $id ===================\n" ;
$o2->title('set a new title');
$response = $_session->request( 'open-ils.batch.schedule.update', $auth, $o2);
my $o3 = Fieldmapper::batch::schedule->new($response->gather());
print 'title=' . $o3->title . "\n";

$id = $o3->id ;
print "==================== delete $id ===================\n" ;
my $response = $_session->request( 'open-ils.batch.schedule.delete', $auth, $id);
my $o4 = $response->gather();
if ( $o4 ) { 
	print 'delete failed. response = ' . $o4 . "\n";
} else {
	print 'delete ok';
}
