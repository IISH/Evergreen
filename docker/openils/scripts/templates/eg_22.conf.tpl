# :vim set syntax apache

LogLevel info
# - log locally
# CustomLog /var/log/apache2/access.log combined
# ErrorLog /var/log/apache2/error.log
# - log to syslog
CustomLog "|/usr/bin/logger -p local7.info" common
ErrorLog syslog:local7


# ----------------------------------------------------------------------------------
# Set up Perl
# ----------------------------------------------------------------------------------

# - needed by CGIs
PerlRequire /etc/apache2/eg_startup
PerlChildInitHandler OpenILS::WWW::OAI::child_init
PerlChildInitHandler OpenILS::WWW::Archive::child_init
PerlChildInitHandler OpenILS::WWW::Reporter::child_init
PerlChildInitHandler OpenILS::WWW::SuperCat::child_init
PerlChildInitHandler OpenILS::WWW::AddedContent::child_init
PerlChildInitHandler OpenILS::WWW::AutoSuggest::child_init
PerlChildInitHandler OpenILS::WWW::PhoneList::child_init

# ----------------------------------------------------------------------------------
# Set some defaults for our working directories
# ----------------------------------------------------------------------------------
<Directory {{env['OPENILS_SYSDIR']}}/var/web>
    Order allow,deny
    Allow from all
</Directory>


# ----------------------------------------------------------------------------------
# XUL directory
# ----------------------------------------------------------------------------------
<Directory {{env['OPENILS_SYSDIR']}}/var/web/xul>
   Options Indexes FollowSymLinks
   AllowOverride None
   Order allow,deny
   Allow from all
</Directory>


# ----------------------------------------------------------------------------------
# Remove the language portion from the URL
# ----------------------------------------------------------------------------------
AliasMatch ^/opac/.*/skin/(.*)/(.*)/(.*) {{env['OPENILS_SYSDIR']}}/var/web/opac/skin/$1/$2/$3
AliasMatch ^/opac/.*/extras/slimpac/(.*) {{env['OPENILS_SYSDIR']}}/var/web/opac/extras/slimpac/$1
AliasMatch ^/opac/.*/extras/selfcheck/(.*) {{env['OPENILS_SYSDIR']}}/var/web/opac/extras/selfcheck/$1



# ----------------------------------------------------------------------------------
# System config CGI scripts go here
# ----------------------------------------------------------------------------------
{%- if env.get('APACHE_OFFLINE', "false") == "true" %}
Alias /cgi-bin/offline/ "{{env['OPENILS_SYSDIR']}}/var/cgi-bin/offline/"
<Directory "{{env['OPENILS_SYSDIR']}}/var/cgi-bin/offline">
	AddHandler cgi-script .cgi .pl
	AllowOverride None
	Options None
	Order deny,allow
	Deny from all
	Allow from all
	Options FollowSymLinks ExecCGI Indexes
</Directory>
{%- endif %}

# ----------------------------------------------------------------------------------
# Updates folder
# ----------------------------------------------------------------------------------
Alias /updates/ "{{env['OPENILS_SYSDIR']}}/var/updates/pub/"
<Directory "{{env['OPENILS_SYSDIR']}}/var/updates/pub">
	<Files check>
		ForceType cgi-script
	</Files>
	<Files update.rdf>
		ForceType cgi-script
	</Files>
	<Files manualupdate.html>
		ForceType cgi-script
	</Files>
	<Files download>
		ForceType cgi-script
	</Files>
	AllowOverride None
	Options None
	Allow from all
	Options ExecCGI
</Directory>


# ----------------------------------------------------------------------------------
# OPTIONAL: Set how long the client will cache our content.  Change to suit
# ----------------------------------------------------------------------------------
ExpiresActive On
ExpiresDefault "access plus 1 month"
ExpiresByType text/html "access plus 18 hours"
ExpiresByType application/xhtml+xml "access plus 18 hours"
ExpiresByType application/x-javascript "access plus 18 hours"
ExpiresByType application/javascript "access plus 18 hours"
ExpiresByType text/css "access plus 50 minutes"

# ----------------------------------------------------------------------------------
# Set up our SSL virtual host
# ----------------------------------------------------------------------------------
NameVirtualHost *:443
<VirtualHost *:443>
	ServerName ServerName {{env['APACHE_SERVER_NAME']}}
	ServerAlias *
	DocumentRoot "{{env['OPENILS_SYSDIR']}}/var/web"
	SSLEngine on
    SSLProxyEngine on # required for ErrorDocument 404 on SSL connections
	SSLHonorCipherOrder On
	SSLCipherSuite ECDHE-RSA-AES256-SHA384:AES256-SHA256:RC4:HIGH:!MD5:!aNULL:!EDH:!AESGCM

	# If you don't have an SSL cert, you can create self-signed
	# certificate and key with:
	# openssl req -new -x509 -nodes -out server.crt -keyout server.key
	SSLCertificateFile /etc/ssl/server.crt
	SSLCertificateKeyFile /etc/ssl/server.key

	# - absorb the shared virtual host settings
	Include eg_vhost.conf

	# help IE along with SSL pages
	SetEnvIf User-Agent ".*MSIE [1-5].*" \
	nokeepalive ssl-unclean-shutdown \
	downgrade-1.0 force-response-1.0

	SetEnvIf User-Agent ".*MSIE [6-9].*" \
	ssl-unclean-shutdown

    {%- if env['APACHE_WEB_TEMPLATE_PATH'] %}
	<Location /eg>
	PerlAddVar OILSWebTemplatePath {{env['APACHE_WEB_TEMPLATE_PATH']}}
	</Location>
    {%- endif %}

</VirtualHost>

# ----------------------------------------------------------------------------------
# Set up our main virtual host
# Port 80 comes after 443 to avoid "unknown protocol speaking not SSL to HTTPS port!?"
# errors, per http://wiki.apache.org/httpd/InternalDummyConnection
# ----------------------------------------------------------------------------------

# Commented to avoid warnings from duplicate "NameVirtualHost: *80" directives
# NameVirtualHost *:80
<VirtualHost *:80>
	ServerName ServerName {{env['APACHE_SERVER_NAME']}}
	ServerAlias *
 	DocumentRoot {{env['OPENILS_SYSDIR']}}/var/web/
	DirectoryIndex index.xml index.html index.xhtml
    # - absorb the shared virtual host settings
    Include eg_vhost.conf

    {%- if env['APACHE_WEB_TEMPLATE_PATH'] %}
    <Location /eg>
        PerlAddVar OILSWebTemplatePath {{env['APACHE_WEB_TEMPLATE_PATH']}}
    </Location>
    {%- endif %}

</VirtualHost>