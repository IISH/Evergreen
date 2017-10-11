#!/usr/bin/perl
use OpenSRF::AppSession;

# default ingress value for all Apache/mod_perl clients
OpenSRF::AppSession->ingress('apache');

use OpenILS::WWW::BatchUpdate qw( {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml );
use OpenILS::WWW::BatchEnrich qw( {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml );
use OpenILS::WWW::OAI qw( {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml );
use OpenILS::WWW::Archive qw( {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml );
use OpenILS::WWW::Exporter qw( {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml );
use OpenILS::WWW::SuperCat qw( {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml );
use OpenILS::WWW::AddedContent qw( {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml );
use OpenILS::WWW::Proxy ('{{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml');
use OpenILS::WWW::Vandelay qw( {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml );
use OpenILS::WWW::TemplateBatchBibUpdate qw( {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml );
use OpenILS::WWW::EGWeb  ('{{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml');
use OpenILS::WWW::IDL2js ('{{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml');
use OpenILS::WWW::FlatFielder;
use OpenILS::WWW::PhoneList ('{{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml');

# - Uncomment the following 2 lines to make use of the IP redirection code
# - The IP file should to contain a map with the following format:
# - actor.org_unit.shortname <start_ip> <end_ip>
    # - e.g.  LIB123 10.0.0.1 10.0.0.254

    #use OpenILS::WWW::Redirect qw({{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml);
    #OpenILS::WWW::Redirect->parse_ips_file('{{env['OPENILS_SYSDIR']}}/conf/lib_ips.txt');



    1;
