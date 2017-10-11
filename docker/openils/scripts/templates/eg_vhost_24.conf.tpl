# ----------------------------------------------------------------------------------
# This is the global Evergreen virtual host config.  Anything you want published
# through all virtual hosts (port 80, port 443, etc.) should live in here.
# ----------------------------------------------------------------------------------

# ----------------------------------------------------------------------------------
# Point / to the opac - if you have a custom skin or locale, point at it here
# ----------------------------------------------------------------------------------
RewriteRule ^/$ %{REQUEST_SCHEME}://%{HTTP_HOST}/eg/opac/home [R=301,L]

# ----------------------------------------------------------------------------------
# Redirect staff to the correct URL if they forget to include the final /
# ----------------------------------------------------------------------------------
RewriteRule ^/eg/staff$ https://%{HTTP_HOST}/eg/staff/ [R=301,L]

# ----------------------------------------------------------------------------------
# Point / to the IP address redirector
# ----------------------------------------------------------------------------------
#<LocationMatch ^/$>
#    SetHandler perl-script
#    PerlHandler OpenILS::WWW::Redirect
#    Options +ExecCGI
#    PerlSendHeader On
#    #PerlSetVar OILSRedirectSkin "default"
#    # OILSRedirectDepth defaults to the depth of the branch that the OPAC was directed to
#    #PerlSetVar OILSRedirectDepth "0"
#    #PerlSetVar OILSRedirectLocale "en-US"
#    # Use the template-toolkit opac
#    #PerlSetVar OILSRedirectTpac "true"
#    allow from all
#</LocationMatch>


# ----------------------------------------------------------------------------------
# Assign a default locale to the accessible OPAC
# ----------------------------------------------------------------------------------
RewriteRule ^/opac/extras/slimpac/start.html$ %{REQUEST_SCHEME}://%{HTTP_HOST}/opac/en-US/extras/slimpac/start.html [R=301,L]
RewriteRule ^/opac/extras/slimpac/advanced.html$ %{REQUEST_SCHEME}://%{HTTP_HOST}/opac/en-US/extras/slimpac/advanced.html [R=301,L]

# ----------------------------------------------------------------------------------
# Configure the gateway and translator
# ----------------------------------------------------------------------------------
OSRFGatewayConfig {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml
OSRFTranslatorConfig {{env['OPENILS_SYSDIR']}}/conf/opensrf_core.xml
# Translator memcache server.  Default is localhost
OSRFTranslatorCacheServer {{env['OPENILS_MEMCACHED_SERVER']}}


# ----------------------------------------------------------------------------------
# Added content plugin
# ----------------------------------------------------------------------------------
<Location /opac/extras/ac/>
SetHandler perl-script
PerlHandler OpenILS::WWW::AddedContent
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>

# Lock clearing cache down to STAFF_LOGIN
<Location /opac/extras/ac/clearcache/>
PerlAccessHandler OpenILS::WWW::AccessHandler
PerlSetVar OILSAccessHandlerPermission "STAFF_LOGIN"
</Location>

# Autosuggest for searches
<Location /opac/extras/autosuggest>
SetHandler perl-script
PerlHandler OpenILS::WWW::AutoSuggest
PerlSendHeader On
Require all granted
</Location>

# Flattener service
<Location /opac/extras/flattener>
SetHandler perl-script
PerlHandler OpenILS::WWW::FlatFielder
PerlSendHeader On
Require all granted
</Location>

# ----------------------------------------------------------------------------------
# Replace broken cover images with a transparent GIF by default
# ----------------------------------------------------------------------------------
RewriteEngine ON
RewriteRule ^/opac/extras/ac/jacket/(small|medium|large)/$ \
/opac/images/blank.png [P,L]

<Location /opac/extras/ac/jacket>
ErrorDocument 404 /opac/images/blank.png
</Location>

# Uncomment one or more of these to have a "no image" image other than the blank
# image above.

# Note: There are no default images provided for these, you will need to provide
# your own "no image" image(s).

#<Location /opac/extras/ac/jacket/small>
#        ErrorDocument 404 /opac/images/noimage_small.png
#</Location>

#<Location /opac/extras/ac/jacket/medium>
#        ErrorDocument 404 /opac/images/noimage_medium.png
#</Location>

#<Location /opac/extras/ac/jacket/large>
#        ErrorDocument 404 /opac/images/noimage_large.png
#</Location>

# ----------------------------------------------------------------------------------
# Add the row ID (RID) and date so we can make unAPI happy
# ----------------------------------------------------------------------------------
RewriteCond %{QUERY_STRING} (^r|&r)=(\d+)
RewriteRule . - [E=OILS_OPAC_RID:%2,E=OILS_TIME_YEAR:%{TIME_YEAR}]

# ----------------------------------------------------------------------------------
# Pull the locale from the URL
# ----------------------------------------------------------------------------------
RewriteCond %{REQUEST_URI} ^/opac/(.*?)/
RewriteRule . - [E=locale:%1]

# ----------------------------------------------------------------------------------
# Rewrite JSPac->TPac with redirects
# ----------------------------------------------------------------------------------
# My Account
RewriteRule /opac/[^/]*/skin/default/xml/myopac.xml %{REQUEST_SCHEME}://%{HTTP_HOST}/eg/opac/myopac/main?%{ENV:OILS_JSPAC_SEARCH_TYPE}%{ENV:OILS_JSPAC_SEARCH_TERMS}%{ENV:OILS_JSPAC_SEARCH_LOCATION} [NE,R,L]

# -----------------------------------------------------------------------------$
# Force HTTPS for /eg/circ/selfcheck
# -----------------------------------------------------------------------------$
RewriteCond %{HTTPS} off
RewriteRule ^(/eg/circ/selfcheck) https://%{HTTP_HOST}%{REQUEST_URI} [NC,R=301,L]

# ----------------------------------------------------------------------------------
# For sanity reasons, default indexes to Off
# ----------------------------------------------------------------------------------
Options -Indexes

# ----------------------------------------------------------------------------------
# Configure the OPAC
# ----------------------------------------------------------------------------------
<LocationMatch /opac/>
SSILegacyExprParser on
AddType application/xhtml+xml .xml

# - configure mod_xmlent
XMLEntStripPI "yes"
XMLEntEscapeScript "no"
XMLEntStripComments "yes"
XMLEntContentType "text/html; charset=utf-8"
# forces quirks mode which we want for now
XMLEntStripDoctype "yes"

# - set up the include handlers
Options +Includes
AddOutputFilter INCLUDES .xsl
AddOutputFilter INCLUDES;XMLENT .xml

SetEnvIf Request_URI ".*" OILS_OPAC_BASE=/opac/

# This gives you the option to configure a different host to serve OPAC images from
# Specify the hostname (without protocol) and path to the images.  Protocol will
# be determined at runtime
#SetEnvIf Request_URI ".*" OILS_OPAC_IMAGES_HOST=static.example.org/opac/

# In addition to loading images from a static host, you can also load CSS and/or
# Javascript from a static host or hosts. Protocol will be determined at runtime
# and/or by configuration options immediately following.
#SetEnvIf Request_URI ".*" OILS_OPAC_CSS_HOST=static.example.org/opac/
#SetEnvIf Request_URI ".*" OILS_OPAC_JS_HOST=static.example.org/opac/

# If you are not able to serve static content via https and
# wish to force http:// (and are comfortable with mixed-content
# warnings in client browsers), set this:
#SetEnvIf Request_URI ".*" OILS_OPAC_STATIC_PROTOCOL=http

# If you would prefer to fall back to your non-static servers for
# https pages, avoiding mixed-content warnings in client browsers
# and are willing to accept some increased server load, set this:
#SetEnvIf Request_URI ".*" OILS_OPAC_BYPASS_STATIC_FOR_HTTPS=yes

# Specify a ChiliFresh account to integrate their services with the OPAC
#SetEnv OILS_CHILIFRESH_ACCOUNT
#SetEnv OILS_CHILIFRESH_PROFILE
#SetEnv OILS_CHILIFRESH_URL http://chilifresh.com/on-site/js/evergreen.js
#SetEnv OILS_CHILIFRESH_HTTPS_URL https://secure.chilifresh.com/on-site/js/evergreen.js

# Specify the initial script URL for Novelist (containing account credentials, etc.)
#SetEnv OILS_NOVELIST_URL
#

# Uncomment to force SSL any time a patron is logged in.  This protects
# authentication tokens.  Left commented out for backwards compat for now.
#SetEnv OILS_OPAC_FORCE_LOGIN_SSL 1

# If set, the skin uses the combined JS file at $SKINDIR/js/combined.js
#SetEnv OILS_OPAC_COMBINED_JS 1

</LocationMatch>

<Location /opac/>
# ----------------------------------------------------------------------------------
# Some mod_deflate fun
# ----------------------------------------------------------------------------------
<IfModule mod_deflate.c>
    SetOutputFilter DEFLATE

    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html

    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary

    <IfModule mod_headers.c>
        Header append Vary User-Agent env=!dont-vary
    </IfModule>
</IfModule>

</Location>

<Location //opac/>
# ----------------------------------------------------------------------------------
# Some mod_deflate fun
# ----------------------------------------------------------------------------------
<IfModule mod_deflate.c>
    SetOutputFilter DEFLATE

    BrowserMatch ^Mozilla/4 gzip-only-text/html
    BrowserMatch ^Mozilla/4\.0[678] no-gzip
    BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html

    SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary

    <IfModule mod_headers.c>
        Header append Vary User-Agent env=!dont-vary
    </IfModule>
</IfModule>

</Location>

# ----------------------------------------------------------------------------------
# Force SSL on the OPAC's "My Account" page
# ----------------------------------------------------------------------------------
<LocationMatch .*/myopac.xml>
SSLRequireSSL
</LocationMatch>

RewriteCond %{QUERY_STRING} locale=([^&]*)
RewriteRule ^/opac/[a-z]{2}-[A-Z]{2}/extras/slimpac/(.*)$ %{REQUEST_SCHEME}://%{HTTP_HOST}/opac/%1/extras/slimpac/$1? [redirect]
<LocationMatch /opac/[a-z]{2}-[A-Z]{2}/extras/slimpac/>
AddOutputFilter INCLUDES;XMLENT .html
</LocationMatch>

# ----------------------------------------------------------------------------------
# Run server-side XUL and XHTML through xmlent to load the correct XML entities
# ----------------------------------------------------------------------------------
RewriteCond %{HTTP:Accept-Language} ^([a-z]{2}-[A-Z]{2})$
# Default to en-US if we haven't matched a locale of the form xx-YY
RewriteRule .? - [S=4]
RewriteRule ^/xul/      -       [E=locale:en-US]
RewriteRule ^/reports/  -       [E=locale:en-US]
RewriteRule .? - [E=locale:en-US]
RewriteRule .? - [S=3]
# Otherwise, set our real locale
RewriteRule ^/xul/      -       [E=locale:%{HTTP:Accept-Language}]
RewriteRule ^/reports/  -       [E=locale:%{HTTP:Accept-Language}]
RewriteRule .? - [E=locale:%{HTTP:Accept-Language}]

<LocationMatch /xul/.*\.x?html$>
SSILegacyExprParser on
Options +Includes
XMLEntEscapeScript "no"
XMLEntStripComments "yes"
XMLEntStripPI "yes"
XMLEntStripDoctype "yes"
XMLEntContentType "text/html; charset=utf-8"
AddOutputFilter INCLUDES;XMLENT .xhtml
AddOutputFilter INCLUDES;XMLENT .html
SetEnv no-gzip
Require all granted
</LocationMatch>


<LocationMatch /xul/.*\.xul$>
SSILegacyExprParser on
Options +Includes
XMLEntContentType "application/vnd.mozilla.xul+xml"
AddOutputFilter INCLUDES;XMLENT .xul
SetEnv no-gzip
Require all granted
</LocationMatch>

# ----------------------------------------------------------------------------------
# Custom modules
# ----------------------------------------------------------------------------------
<Location /opac/extras/oai>
SetHandler perl-script
PerlHandler OpenILS::WWW::OAI
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>

<Location /opac/extras/archive>
SetHandler perl-script
PerlHandler OpenILS::WWW::Archive
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>

<Location /opac/extras/schedule>
SetHandler perl-script
AuthType Basic
AuthName "Batch Update Login"
PerlOptions +GlobalRequest
PerlSetVar OILSProxyPermissions "STAFF_LOGIN"
PerlAuthenHandler OpenILS::WWW::Proxy::Authen
require valid-user
PerlHandler OpenILS::WWW::BatchUpdate
PerlSendHeader On
Options +ExecCGI
Require all granted
</Location>

<Location /opac/extras/enrich>
SetHandler perl-script
AuthType Basic
AuthName "Report Enrich Login"
PerlOptions +GlobalRequest
PerlSetVar OILSProxyPermissions "STAFF_LOGIN"
PerlAuthenHandler OpenILS::WWW::Proxy::Authen
require valid-user
PerlHandler OpenILS::WWW::BatchEnrich
PerlSendHeader On
Options +ExecCGI
Require all granted
</Location>


# ----------------------------------------------------------------------------------
# Supercat feeds
# ----------------------------------------------------------------------------------
<Location /opac/extras/oisbn>
SetHandler perl-script
PerlHandler OpenILS::WWW::SuperCat::oisbn
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>
<Location /opac/extras/supercat>
SetHandler perl-script
PerlHandler OpenILS::WWW::SuperCat::supercat
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>
<Location /opac/extras/unapi>
SetHandler perl-script
PerlHandler OpenILS::WWW::SuperCat::unapi
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>
<Location /opac/extras/feed/bookbag>
SetHandler perl-script
PerlHandler OpenILS::WWW::SuperCat::bookbag_feed
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>
<Location /opac/extras/opensearch>
SetHandler perl-script
PerlHandler OpenILS::WWW::SuperCat::opensearch_feed
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>
<Location /opac/extras/sru>
SetHandler perl-script
PerlHandler OpenILS::WWW::SuperCat::sru_search
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>
<Location /opac/extras/sru_auth>
SetHandler perl-script
PerlHandler OpenILS::WWW::SuperCat::sru_auth_search
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>
<Location /opac/extras/feed/freshmeat>
SetHandler perl-script
PerlHandler OpenILS::WWW::SuperCat::changes_feed
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>
<Location /opac/extras/browse>
SetHandler perl-script
PerlHandler OpenILS::WWW::SuperCat::string_browse
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>
<Location /opac/extras/startwith>
SetHandler perl-script
PerlHandler OpenILS::WWW::SuperCat::string_startwith
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>

# ----------------------------------------------------------------------------------
# Module for displaying OpenSRF API documentation
# ----------------------------------------------------------------------------------
<Location /opac/extras/docgen.xsl>
AddOutputFilter INCLUDES .xsl
</Location>

# ----------------------------------------------------------------------------------
# Module for processing staff-client offline scripts lives here
# ----------------------------------------------------------------------------------
<Directory "{{env['OPENILS_SYSDIR']}}/var/cgi-bin/offline">
AddHandler cgi-script .pl
AllowOverride None
Options +ExecCGI
Require all granted
</Directory>


# ----------------------------------------------------------------------------------
# XXX Note, it's important to explicitly set the JSON encoding style
# (OSRFGatewayLegacyJSON), since the default encoding style will likely change
# with OpenSRF 1.0
# ----------------------------------------------------------------------------------
# OpenSRF JSON legacy gateway
# ----------------------------------------------------------------------------------
<Location /gateway>
SetHandler osrf_json_gateway_module
OSRFGatewayLegacyJSON "true"
Require all granted
</Location>
# ----------------------------------------------------------------------------------
# New-style OpenSRF JSON gateway
# ----------------------------------------------------------------------------------
<Location /osrf-gateway-v1>
SetHandler osrf_json_gateway_module
OSRFGatewayLegacyJSON "false"
Require all granted
</Location>

# ----------------------------------------------------------------------------------
# OpenSRF-over-HTTP translator
# (http://open-ils.org/dokuwiki/doku.php?id=opensrf_over_http)
# ----------------------------------------------------------------------------------
<Location /osrf-http-translator>
SetHandler osrf_http_translator_module
Require all granted
</Location>

# ----------------------------------------------------------------------------------
# The exporter lives here
# ----------------------------------------------------------------------------------
<Location /exporter>
SetHandler perl-script
AuthType Basic
AuthName "Exporter Login"
PerlOptions +GlobalRequest
PerlSetVar OILSProxyPermissions "STAFF_LOGIN"
PerlAuthenHandler OpenILS::WWW::Proxy::Authen
Require valid-user
PerlHandler OpenILS::WWW::Exporter
Options +ExecCGI
PerlSendHeader On
</Location>

<Location /opac/extras/merge_template>
SetHandler perl-script
AuthType Basic
AuthName "Batch Update Login"
PerlOptions +GlobalRequest
PerlSetVar OILSProxyPermissions "STAFF_LOGIN"
PerlAuthenHandler OpenILS::WWW::Proxy::Authen
Require valid-user
PerlHandler OpenILS::WWW::TemplateBatchBibUpdate
PerlSendHeader On
Options +ExecCGI
</Location>

<Location /opac/extras/circ>
AuthType Basic
AuthName "Circ Extras Login"
PerlOptions +GlobalRequest
PerlSetVar OILSProxyPermissions "STAFF_LOGIN"
PerlAuthenHandler OpenILS::WWW::Proxy::Authen
Require valid-user
Options +ExecCGI
PerlSendHeader On
</Location>

<Location /collections>
SetHandler perl-script
AuthType Basic
AuthName "Collections Login"
PerlOptions +GlobalRequest
PerlSetVar OILSProxyPermissions "money.collections_tracker.create"
PerlAuthenHandler OpenILS::WWW::Proxy::Authen
Require valid-user
Options +ExecCGI
PerlSendHeader On
</Location>

# ----------------------------------------------------------------------------------
# Protect Standalone/Offline mode files from public view
# ----------------------------------------------------------------------------------
<Location /standalone/>
AuthType Basic
AuthName "Standalone Mode Login"
PerlOptions +GlobalRequest
PerlSetVar OILSProxyPermissions "STAFF_LOGIN"
PerlAuthenHandler OpenILS::WWW::Proxy::Authen
Require valid-user
PerlSendHeader On
allow from all
SSLRequireSSL
</Location>

# ----------------------------------------------------------------------------------
# Reporting output lives here
# ----------------------------------------------------------------------------------
<Location /reporter/>
AuthType Basic
AuthName "Report Login"
PerlOptions +GlobalRequest
PerlSetVar OILSProxyPermissions "VIEW_REPORT_OUTPUT"
PerlAuthenHandler OpenILS::WWW::Proxy::Authen
Require valid-user
Options +ExecCGI
PerlSendHeader On
</Location>

# ----------------------------------------------------------------------------------
# Reports GUI
# ----------------------------------------------------------------------------------
<LocationMatch /reports.*\.x?html>
SSILegacyExprParser on
Options +Includes
XMLEntContentType "text/html; charset=utf-8"
AddOutputFilter INCLUDES;XMLENT .xhtml
AddOutputFilter INCLUDES;XMLENT .html
</LocationMatch>

<LocationMatch /reports>
SSILegacyExprParser on
Options +Includes
AddOutputFilter INCLUDES;XMLENT .xhtml
</LocationMatch>

# capture locale CGI param for /reports/fm_IDL.xml
RewriteCond %{REQUEST_URI} ^/reports/fm_IDL.xml
RewriteCond %{QUERY_STRING} locale=([^&;]*)
RewriteRule . - [E=locale:%1]

<LocationMatch /reports/fm_IDL.xml>
IDLChunkStripPI "yes"
IDLChunkEscapeScript "no"
IDLChunkStripComments "yes"
IDLChunkStripDoctype "yes"
IDLChunkContentType "application/xml; charset=utf-8"
AddOutputFilter INCLUDES;IDLCHUNK .xml
SetEnv no-gzip
</LocationMatch>

# ----------------------------------------------------------------------------------
# EDI Message viewer
# ----------------------------------------------------------------------------------
<Location /edi>
SetHandler perl-script
PerlHandler OpenILS::WWW::EDI
Options +ExecCGI
PerlSendHeader On
Require all granted
</Location>

# ----------------------------------------------------------------------------------
# XML-RPC gateway
# ----------------------------------------------------------------------------------
<Location /xml-rpc>
SetHandler perl-script
PerlHandler OpenILS::WWW::XMLRPCGateway
Options +ExecCGI
PerlSendHeader On
Require all granted
<IfModule mod_headers.c>
    Header onsuccess set Cache-Control no-cache
</IfModule>
</Location>

# ----------------------------------------------------------------------------------
# Conify - next-generation Evergreen administration interface
# ----------------------------------------------------------------------------------
RewriteRule ^/conify/([a-z]{2}-[A-Z]{2})/global/(.*)$ /conify/global/$2 [E=locale:$1,L]
<Location /conify>
SSILegacyExprParser on
Options +Includes
XMLEntStripPI "yes"
XMLEntEscapeScript "no"
XMLEntStripComments "no"
XMLEntContentType "text/html; charset=utf-8"
AddOutputFilter INCLUDES;XMLENT .html

AuthType Basic
AuthName "Dojo Admin Login"
PerlOptions +GlobalRequest
PerlSetVar OILSProxyPermissions "STAFF_LOGIN"
PerlAuthenHandler OpenILS::WWW::Proxy::Authen
Require valid-user
Options +ExecCGI
PerlSendHeader On
</Location>

# ----------------------------------------------------------------------------------
# The PhoneList lives here
# ----------------------------------------------------------------------------------
<Location /phonelist>
SetHandler perl-script
AuthType Basic
AuthName "PhoneList Login"
Require valid-user
PerlOptions +GlobalRequest
PerlSetVar OILSProxyPermissions "STAFF_LOGIN"
PerlHandler OpenILS::WWW::PhoneList
PerlAuthenHandler OpenILS::WWW::Proxy::Authen
Options +ExecCGI
PerlSendHeader On
<IfModule mod_headers.c>
    Header onsuccess set Cache-Control no-cache
</IfModule>
</Location>
<Location /vandelay-upload>
SetHandler perl-script
PerlHandler OpenILS::WWW::Vandelay::spool_marc
Options +ExecCGI
Require all granted
</Location>

# OpenURL 0.1 searching based on OpenSearch
RewriteMap openurl prg:{{env['OPENILS_SYSDIR']}}/bin/openurl_map.pl
RewriteCond %{QUERY_STRING} (^.*$)
RewriteRule ^/openurl$ ${openurl:%1} [NE,PT]



# General Evergreen web template processor
<Location /eg>
SetHandler perl-script
PerlHandler OpenILS::WWW::EGWeb
Options +ExecCGI
PerlSendHeader On
Require all granted

PerlSetVar OILSWebBasePath "/eg"
PerlSetVar OILSWebWebDir "{{env['OPENILS_SYSDIR']}}/var/web"
PerlSetVar OILSWebDefaultTemplateExtension "tt2"

# Port Apache listens on for HTTP traffic.  Used for HTTP requests
# routed from Perl handlers back to the same Apache instance, like
# added content requests.  Use this when running Apache with a
# non-standard port, typical with a proxy setup.  Defaults to "80".
# PerlSetVar OILSWebInternalHTTPPort "7080"

# Enable Template-Toolkit error debugging messages (apache error log)
PerlSetVar OILSWebDebugTemplate "false"
# local cache of compiled Template Toolkit templates
PerlSetVar OILSWebCompiledTemplateCache "/tmp/eg_template_cache"
# template TTL - how long, in seconds, that Template Toolkit
# waits to check for updated template files
#PerlSetVar OILSWebTemplateStatTTL 60

# -------------------------------------------------------
# Media Prefix.  In the 3rd example, the protocol (http) is enforced
#PerlSetVar OILSWebMediaPrefix "/media"
#PerlSetVar OILSWebMediaPrefix "static.example.com/media"
#PerlSetVar OILSWebMediaPrefix "http://static.example.com/media"

# Locale messages files:
#
# These appear in pairs; the first represents the user agent
# Accept-Language header locale, and the second represents
# the fully-qualified path for the corresponding PO file that
# contains the messages.
#
# If you enable two or more locales, then users will be able to
# select their preferred locale from a locale picker in the TPAC.
#
#PerlAddVar OILSWebLocale "en"
#PerlAddVar OILSWebLocale "{{env['OPENILS_SYSDIR']}}/var/data/locale/opac/messages.en.po"
#PerlAddVar OILSWebLocale "en_ca"
#PerlAddVar OILSWebLocale "{{env['OPENILS_SYSDIR']}}/var/data/locale/opac/en-CA.po"
#PerlAddVar OILSWebLocale "fr_ca"
#PerlAddVar OILSWebLocale "{{env['OPENILS_SYSDIR']}}/var/data/locale/opac/fr-CA.po"

# Set the default locale: defaults to en-US
#PerlAddVar OILSWebDefaultLocale "fr_ca"

# Templates will be loaded from the following paths in reverse order.
PerlAddVar OILSWebTemplatePath "{{env['OPENILS_SYSDIR']}}/var/templates"
#PerlAddVar OILSWebTemplatePath "{{env['OPENILS_SYSDIR']}}/var/templates_localskin"

#-------------------------------------------------
# Added Content Configuration
#-------------------------------------------------
# Content Cafe
#SetEnv OILS_CONTENT_CAFE_USER MYUSER
#SetEnv OILS_CONTENT_CAFE_PASS MYPASS

# LibraryThing
#SetEnv OILS_LIBRARYTHING_URL http://ltfl.librarything.com/forlibraries/widget.js?id=MYID
#SetEnv OILS_LIBRARYTHING_HTTPS_URL https://ltfl.librarything.com/forlibraries/widget.js?id=MYID

# ChiliFresh
#SetEnv OILS_CHILIFRESH_ACCOUNT
#SetEnv OILS_CHILIFRESH_URL http://chilifresh.com/on-site/js/evergreen.js
#SetEnv OILS_CHILIFRESH_HTTPS_URL https://secure.chilifresh.com/on-site/js/evergreen.js

# Novelist
# SetEnv OILS_NOVELIST_URL http://imageserver.ebscohost.com/novelistselect/ns2init.js
# SetEnv OILS_NOVELIST_PROFILE <profile>
    # SetEnv OILS_NOVELIST_PASSWORD <password>

        #-------------------------------------------------

        <IfModule mod_deflate.c>
            SetOutputFilter DEFLATE
            BrowserMatch ^Mozilla/4 gzip-only-text/html
            BrowserMatch ^Mozilla/4\.0[678] no-gzip
            BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html
            SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
            <IfModule mod_headers.c>
                Header append Cache-Control "public"
                Header append Vary User-Agent env=!dont-vary
            </IfModule>
        </IfModule>
        </Location>
        <LocationMatch ^/(images|css|js)/>
        # should pick up the default expire time from eg.conf...
        <IfModule mod_deflate.c>
            SetOutputFilter DEFLATE
            BrowserMatch ^Mozilla/4 gzip-only-text/html
            BrowserMatch ^Mozilla/4\.0[678] no-gzip
            BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html
            SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
            <IfModule mod_headers.c>
                Header append Cache-Control "public"
                Header append Vary User-Agent env=!dont-vary
            </IfModule>
        </IfModule>
        </LocationMatch>
        <Location /eg/opac>
        PerlSetVar OILSWebContextLoader "OpenILS::WWW::EGCatLoader"
        # Expire the HTML quickly since we're loading dynamic data for each page
        ExpiresActive On
        ExpiresByType text/html "access plus 5 seconds"
        </Location>
        <Location /eg/kpac>
        PerlSetVar OILSWebContextLoader "OpenILS::WWW::EGKPacLoader"
        PerlSetVar KPacConfigFile "{{env['OPENILS_SYSDIR']}}/conf/kpac.xml.example"
        ExpiresActive On
        ExpiresByType text/html "access plus 5 seconds"
        </Location>

        # Note: the template processor will decline handling anything it does not
        # have an explicit configuration for, which means it will fall back to
        # Apache to serve the file.  However, in the interest of speed, go ahead
        # and tell Apache to avoid asking OpenILS::WWW::EGWeb for static content.
        # Add more exemptions as needed.
        <LocationMatch ^/eg/.*(\.js|\.html|\.xhtml|\.xml|\.jpg|\.png|\.gif)$>
        SetHandler None
        </LocationMatch>

        # ----------------------------------------------------------------------------------
        # Some mod_deflate setup
        # ----------------------------------------------------------------------------------
        <IfModule mod_deflate.c>

            ## optional logging for mod_deflate debugging
            ##DeflateFilterNote Input instream
            ##DeflateFilterNote Output outstream
            ##DeflateFilterNote Ratio ratio
            ##
            ##LogFormat '"%r" %{outstream}n/%{instream}n (%{ratio}n%%)' deflate
            ##CustomLog /var/log/apache2/deflate_log deflate

            # There are problems with XMLENT and mod_deflate - so lets disable it
            # This is where we don't have a pre-existing LocationMatch directive earlier
            <LocationMatch /opac/.*\.xml$>
            SetEnv no-gzip
            </LocationMatch>
            <LocationMatch /opac/[a-z]{2}-[A-Z]{2}/extras/slimpac/.*\.html$>
            SetEnv no-gzip
            </LocationMatch>
            <LocationMatch /reports/.*\.xhtml$>
            SetEnv no-gzip
            </LocationMatch>
            <LocationMatch /conify/.*\.html$>
            SetEnv no-gzip
            </LocationMatch>
        </IfModule>


        <Location /IDL2js>

        SetHandler perl-script
        PerlHandler OpenILS::WWW::IDL2js
        Options +ExecCGI
        PerlSendHeader On
        Require all granted

        <IfModule mod_headers.c>
            Header append Cache-Control "public"
        </IFModule>

        <IfModule mod_deflate.c>
            SetOutputFilter DEFLATE
            BrowserMatch ^Mozilla/4 gzip-only-text/html
            BrowserMatch ^Mozilla/4\.0[678] no-gzip
            BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html
            SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
            <IfModule mod_headers.c>
                Header append Vary User-Agent env=!dont-vary
            </IfModule>
        </IfModule>
        </Location>

        <LocationMatch /eg/staff/>
        SSLRequireSSL
        Options -MultiViews
        PerlSetVar OILSWebStopAtIndex "true"

        RewriteCond %{HTTPS} off
        RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [NE,R,L]

        # sample staff-specific translation files
        #PerlAddVar OILSWebLocale "en_ca"
        #PerlAddVar OILSWebLocale "{{env['OPENILS_SYSDIR']}}/var/data/locale/staff/en-CA.po"
        #PerlAddVar OILSWebLocale "fr_ca"
        #PerlAddVar OILSWebLocale "{{env['OPENILS_SYSDIR']}}/var/data/locale/staff/fr-CA.po"
        </LocationMatch>

        <Location /js/>
        <IfModule mod_headers.c>
            Header append Cache-Control "public"
        </IFModule>
        <IfModule mod_deflate.c>
            SetOutputFilter DEFLATE
            BrowserMatch ^Mozilla/4 gzip-only-text/html
            BrowserMatch ^Mozilla/4\.0[678] no-gzip
            BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html
            SetEnvIfNoCase Request_URI \.(?:gif|jpe?g|png)$ no-gzip dont-vary
            <IfModule mod_headers.c>
                Header append Vary User-Agent env=!dont-vary
            </IfModule>
        </IfModule>
        </Location>


        # Uncomment the following to force SSL for everything. Note that this defeats caching
        # and you will suffer a performance hit.
        #RewriteCond %{HTTPS} off
        #RewriteRule ^ https://%{HTTP_HOST}%{REQUEST_URI} [NE,R,L]