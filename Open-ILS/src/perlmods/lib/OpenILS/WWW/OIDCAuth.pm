# OpenILS::WWW::OIDCAuth provides a database lookup after the auth_openidc_module> has set the sub and other OIDC claims.
#
# Copyright (c) 2026  DI, HuC
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
    my $oidc_sub = $r->headers_in->get('X-Remote-Sub');
    $oidc_sub ||= $ENV{HTTP_X_REMOTE_SUB} || $ENV{X_REMOTE_SUB} || $ENV{OIDC_CLAIM_sub};

    if ($oidc_sub && $oidc_sub ne '(null)') {
        $logger->info("Found oidc_sub: $oidc_sub");
    } else {
        $logger->info("Authentication Error: Missing secure OIDC identity header attributes: $oidc_sub");
        return Apache2::Const::HTTP_UNAUTHORIZED;
    }

    # request open-ils.cstore open-ils.cstore.direct.actor.card.search {"barcode":"blablabla", "active":"t"}
    my $session = OpenSRF::AppSession->create('open-ils.cstore');
    my $card_req = $session->request(
        'open-ils.cstore.direct.actor.card.search',
        {"barcode" => $oidc_sub, active => "t"}
    );
    my $card = $card_req->gather(1);

    if (!$card || $card->class_name eq 'OpenILS::Event') {
        $logger->info("Error: No matching active library account found for identity token.");
        return Apache2::Const::NOT_FOUND;
    }

    my $usr_id = $card->usr;
    $logger->info("Found usr_id $usr_id");

    my $ws_name = $cgi->param('ws');
    my $session_auth = $U->simplereq(
        'open-ils.auth_internal',
        'open-ils.auth_internal.session.create',
        { user_id     => $usr_id,
          workstation => $ws_name,
          login_type  => 'staff',
          provisional => 0
        }
    )->{payload};

    # 6. Set cookie and redirect user directly to target staff web application interface
    my $cookie_list = [
        $cgi->cookie(
            -name     => COOKIE_STAFF_TOKEN,
            -value    => '"'.$session_auth->{authtoken}.'"',
            -path     => '/',
            -secure   => 1
        ),
        ];

    $logger->info("Redirect to /eg2/en-US/staff/splash");
    print $cgi->redirect(
        -uri    => '/eg2/en-US/staff/splash',
        -cookie => $cookie_list,
    );
    return Apache2::Const::REDIRECT;
}

1;