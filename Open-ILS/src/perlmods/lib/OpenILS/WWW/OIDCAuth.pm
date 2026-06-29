# OpenILS::WWW::OIDCAuth provides a database lookup after the auth_openidc_module> has set the sub and other OIDC claims.
#
# Copyright (c) 2026  DI, HuC
#
# UC 1: no workstation
# - retrieve the user_id by barcode using the oicd sub value.
# - if found:
#   - create the token for the user
#   - set the cookies
#   - direct the user to the workstation registration path
#  else 401
#
# UC 2: known workstation
# - retrieve the user_id by barcode with the oicd sub value.
# - if found:
#   - create the token for the user
#   - set the cookie
#   - direct the user to the splash page
#  else 401
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
# Author: Lucien van Wouw <lucien.van.wouw@di.huc.knaw.nl>

package OpenILS::WWW::OIDCAuth;
use strict;
use warnings;

use Apache2::Const -compile => qw(OK REDIRECT HTTP_UNAUTHORIZED HTTP_FORBIDDEN NOT_FOUND HTTP_INTERNAL_SERVER_ERROR :log);
use CGI;
use OpenSRF::EX qw(:try);
use OpenSRF::System;
use OpenSRF::AppSession;
use Encode;
use OpenSRF::Utils::Logger qw/$logger/;
use HTML::Entities;
use OpenSRF::Utils::JSON;
use constant COOKIE_STAFF_TOKEN => 'eg.auth.token';
use constant COOKIE_STAFF_TIMEOUT => 'eg.auth.time';
use constant COOKIE_STAFF_AUTHORITATIVE => 'eg.sys.use_authoritative';

my $U = 'OpenILS::Application::AppUtils';

my ($self, $bootstrap);

sub import {
    $self = shift;
    $bootstrap = shift;
}

sub child_init {
    OpenSRF::System->bootstrap_client(config_file => $bootstrap);
    return Apache2::Const::OK;
}

sub handler {
    my ($r) = @_;

    my $cgi = new CGI;

    # get the oidc sub value. Usually a long hexadecimal string.
    my $oidc_sub = $r->headers_in->get('X-Remote-Sub');
    $oidc_sub ||= $ENV{HTTP_X_REMOTE_SUB} || $ENV{X_REMOTE_SUB} || $ENV{OIDC_CLAIM_sub};
    if ($oidc_sub && $oidc_sub ne '(null)') {
        $logger->info("Found oidc_sub: $oidc_sub");
    } else {
        $logger->info("Authentication Error: Missing secure OIDC identity header attributes: $oidc_sub");
        return Apache2::Const::HTTP_UNAUTHORIZED;
    }

    # Now retrieve a user from the barcode using the oidc sub value..
    my $session = OpenSRF::AppSession->create('open-ils.cstore');
    my $card_req = $session->request(
        'open-ils.cstore.direct.actor.card.search',
        {"barcode" => $oidc_sub, active => "t"}
    );
    my $card = $card_req->gather(1);

    # No user found.
    if (!$card || $card->class_name eq 'OpenILS::Event') {
        $logger->info("Error: No matching active library account found for identity token $oidc_sub");
        $r->content_type('text/html');
        $r->no_cache(1); # disable caching
        my $html = '<html xmlns="http://www.w3.org/1999/xhtml">
            <head><title>User not known</title></head>
            <body>
                <h1>User not known</h1>
                <p>Your barcode <b>' . $oidc_sub . '</b>
                    is not set yet in your Evergreen user profile. Ask your administrator to add this code to use the service.
                </p>
            </body>
        </html>';
        $r->print($html);

        return Apache2::Const::NOT_FOUND;
    }

    my $user_id = $card->usr;
    $logger->info("Found usr_id $user_id");

    # Now get the user details and active status.
    my $user_details = $session->request("open-ils.cstore.direct.actor.user.retrieve", $user_id)->gather(1);
    my $user_hash = ($user_details && ref($user_details)) ? $user_details->to_bare_hash() : undef;
    my $is_active = ($user_hash && $user_hash->{active} && !$user_hash->{deleted});
    $logger->info("User usr_id $user_id account active: $is_active");

    unless ($is_active) {
        my $html = '<html xmlns="http://www.w3.org/1999/xhtml">
                    <head><title>Account not active or expired</title></head>
                    <body>
                        <h1>Account not active or expired</h1>
                        <p>Your account is not enabled or it has expired.
                        Ask your administrator to enable your account to use the service.
                        </p>
                    </body>
                </html>';
                $r->print($html);

        return Apache2::Const::HTTP_UNAUTHORIZED;
    }

    my $args = {
        user_id    => $user_id,
        login_type => 'staff'
    };

    # See if the workstation is known.
    my $ws_name = $cgi->param('ws') // '';
    if ($ws_name ne '') {
        $args->{workstation} = $ws_name;
    }

    # Create a authentication token.
    my $authtoken = $U->simplereq( 'open-ils.auth_internal',
        'open-ils.auth_internal.session.create',
        $args
    )->{payload}->{authtoken};

    unless (defined($authtoken)) {
        $logger->error("Unable to create an authentication token with user_id $user_id and args:");
        while (my ($key, $value) = each %$args) {
            $logger->info("args[$key] => $value");
        }
        return Apache2::Const::HTTP_INTERNAL_SERVER_ERROR;
    }

    # 6. Set cookie and redirect user directly to target staff web application interface
    my $cookie_list = [
        $cgi->cookie(
            -name     => COOKIE_STAFF_TOKEN,
            -value    => '"'.$authtoken.'"',
            -path     => '/',
            -secure   => 1,
            -httponly => 0,
        ),
        $cgi->cookie(
            -name     => COOKIE_STAFF_TIMEOUT,
            -value    => 28800,
            -path     => '/',
            -secure   => 1,
            -httponly => 0,
        ),
        $cgi->cookie(
            -name     => COOKIE_STAFF_AUTHORITATIVE,
            -value    => 0,
            -path     => '/',
            -secure   => 1,
            -httponly => 0,
        )
        ];

    # If we have a known work station, we can proceed to the splash page.
    # If not, we need to let the user set it.
    my $redirect_url = ($ws_name ne '') ? '/eg2/en-US/staff/splash' : '/eg2/en-US/staff/admin/workstation/workstations/manage';
    $logger->info("Redirect to $redirect_url");
    print $cgi->redirect(
        -uri    => $redirect_url,
        -cookie => $cookie_list,
    );
    return Apache2::Const::REDIRECT;
}

1;