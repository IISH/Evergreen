# OpenILS::WWW::Archive returns a report.
#
# Copyright (c) 2014-2016  International Institute of Social History
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


package OpenILS::WWW::Archive;
use strict; use warnings;
use Apache2::Const -compile => qw(OK REDIRECT DECLINED NOT_FOUND :log);
use CGI;


my (
    $bootstrap
);


sub import {
    my $self = shift;
    $bootstrap = shift;
}


sub handler {
    my $cgi = new CGI;
    my $content = `/openils/install/Evergreen-ILS-2.7.1/Open-ILS/src/support-scripts/archive/arcreport.pl`;

    # ANMB.;;906378;;ARCH00218;;$931$a 3214 3|$931$b 0 07|$931$e p|
    my @items = split(/\n/, $content);

    $cgi->header(-type=>'text/html', -charset=>'utf-8');
    $cgi->print('<html><head> Overzicht archievenplaatsnummers</head><body>' .
        '<style type="text/css">' .
        'able.sample td {' .
        '    border: 1px;' .
        '}' .
        'able.sample a {' .
        '        color: #000000;' .
        '   }' .
        '</style>' .
        '<h2>Overzicht archievenplaatsnummers</h2>' .
        '<table border=0 bgcolor="#efefef">' .
        '<td><table bgcolor="#efefef" width="100%" border="0">' .
        '<tr><td width="40%" align="center">&nbsp;Name of Archive</td><td width="10%">Socialhistory.ORG</td><td width="40%" align=center>Holdings</td><td width="10%" align="right">Evergreen</td></tr>' .
        '</table></td></tr>');

    my $count = 0;
    foreach my $item (@items)
    {
       my ($name, $id, $callnumber, $archoldings) = split(/\;\;/, $item);
       $archoldings=~s/\|$//g;

       $archoldings=~s/\|/<br \/>/g;
       my $url = "http://evergreen.iisg.nl/opac/en-US/skin/default/xml/rdetail.xml?r=$id";
       my $searchurl = "http://search.socialhistory.org/Record/$id";
       $searchurl = $url;
       my $socialurl = "<a href=\"http://hdl.handle.net/10622/$callnumber\" target=_blank>$callnumber</a>";
       my $color = "#ffffff";
       $color = "#95B9C7" if ($count % 2 == 0);
       $cgi->print("<tr><td>\n");
       $cgi->print("<table class=\"sample\" bgcolor=$color width=100%>\n");
       $cgi->print("<tr><td width=40%>&nbsp;<a href=\"$url\" target=_blank>$name</a></td><td width=10%>$socialurl</td><td width=40%>$archoldings</td><td width=10% align=right><a href=\"$searchurl\" target=_blank>TCN $id</a></td></tr>\n");
       $cgi->print("</table>\n");
       $cgi->print("</td></tr>\n");
       $count++;
    }
    $cgi->print("</table><p>$count archives</p></body></html>");

    return Apache2::Const::OK;
}


1;
