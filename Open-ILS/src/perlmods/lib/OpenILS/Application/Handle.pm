# OpenILS::Application::Handle handles PID webservices requests
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


package OpenILS::Application::Handle;

use strict;
use warnings;
use HTTP::Request ;
use LWP::UserAgent;
use XML::LibXML;

my $SOAP_NAMESPACE = 'http://schemas.xmlsoap.org/soap/envelope/';
my $PID_NAMESPACE = 'http://pid.socialhistoryservices.org/';

# All OpenSRF applications must be based on OpenSRF::Application or
# a subclass thereof.  Makes sense, eh?
use OpenILS::Application;
use base qw/OpenILS::Application/;

# This is the client class, used for connecting to open-ils.storage
use OpenSRF::AppSession;

# This is an extension of Error.pm that supplies some error types to throw
use OpenSRF::EX qw(:try);

# This is a helper class for querying the OpenSRF Settings application ...
use OpenSRF::Utils::SettingsClient;

# ... and here we have the built in logging helper ...
use OpenSRF::Utils::Logger qw($logger);

my ($handle_endpoint, $handle_authorization, $handle_timeout, $handle_bind_url_available, $handle_bind_url_deleted) ;

sub child_init {
    # we need an XML parser

   my $app_settings = OpenSRF::Utils::SettingsClient->new->config_value(apps => 'open-ils.handle')->{'app_settings'};
   $handle_endpoint = $app_settings->{'endpoint'};
   $handle_authorization = $app_settings->{'authorization'};
   $handle_timeout = $app_settings->{'timeout'};
   $handle_bind_url_available = $app_settings->{'bind_url_available'};
   $handle_bind_url_deleted = $app_settings->{'bind_url_deleted'};
}


# This declare a call to a webservice.
sub upsert_pid {
    my( $self, $conn, $tcn, $handlesystem_naming_authority, $pid, $deleted ) = @_;

    if ( ! $tcn ) {
        $logger->error("tcn $tcn not set.");
        return undef;
    }

    if ( ! $pid ) {
        $logger->error("pid not set.");
        return undef;
    }

    my $resolveUrl = ($deleted) ? $handle_bind_url_deleted : $handle_bind_url_available ;
    $resolveUrl =~ s/%/$tcn/o ;

    my $soap = "<soapenv:Envelope xmlns:soapenv=\"${SOAP_NAMESPACE}\"
                          xmlns:pid=\"${PID_NAMESPACE}\">
            <soapenv:Body>
                <pid:UpsertPidRequest>
                    <pid:na>${handlesystem_naming_authority}</pid:na>
                    <pid:handle>
                        <pid:pid>${pid}</pid:pid>
                        <pid:resolveUrl>${resolveUrl}</pid:resolveUrl>
                    </pid:handle>
                </pid:UpsertPidRequest>
            </soapenv:Body>
        </soapenv:Envelope>";

    # set custom HTTP request header fields
    my $req = HTTP::Request->new(POST => $handle_endpoint);
    $req->header('Content-Type' => 'text/xml');
    $req->header('Authorization' => $handle_authorization);
    $req->content($soap);

    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 0 });
    $ua->agent('Evergreen ILS');
    $ua->timeout($handle_timeout);
    $ua->default_header('Authorization' => $handle_authorization);

    $logger->debug('Sending to ' . $handle_endpoint . "\nMessage: " . $soap) ;

    my $resp = $ua->request($req);

    if ($resp->is_success) {
        my $parser = new XML::LibXML;
        my $xml = $parser->parse_string($resp->content);
        $xml->documentElement->setNamespace($PID_NAMESPACE, 'pid', 1);
        $pid = $xml->documentElement->findvalue('//pid:pid/text()') ;
        return $pid if ( $pid ) ;
    } else {
        $logger->error( 'HTTP code: ' . $resp->code . "\n" . 'HTTP POST error message: ' . $resp->message ) ;
    }

    $logger->warn("Unable to set a PID for tcn ${tcn}") ;
    return undef ;
}

__PACKAGE__->register_method(
    method    => 'upsert_pid',
    api_name  => 'open-ils.handle.upsert_pid',
    api_level => 1,
    argc      => 1,
    signature =>
        { desc     => <<"          DESC",
Add or update the handle
          DESC
          params   =>
            [
                { name => 'tcn',
                  desc => 'A tcn number',
                  type => 'number' },
                { name => 'na',
                    desc => 'The naming authority' ,
                    type => 'string' },
                { name => 'pid',
                  desc => 'The persistent identifier. This is the handle id in the format \'naming authority\\id\'' ,
                  type => 'number' },
                { name => 'deleted',
                  desc => 'The delete status. True or false.' ,
                  type => 'number' }
            ],
          'return' =>
            { desc => 'The PID if successful. Otherwise undef.',
              type => 'string' }
        }
);

1;