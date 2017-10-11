# prefork MPM
# StartServers: number of server processes to start
# MinSpareServers: minimum number of server processes which are kept spare
# MaxSpareServers: maximum number of server processes which are kept spare
# MaxRequestWorkers: maximum number of server processes allowed to start
# MaxConnectionsPerChild: maximum number of requests a server process serves

<IfModule mpm_prefork_module>
    MaxRequestWorkers	  150
    MaxConnectionsPerChild   0
    StartServers        {{env['APACHE_MPM_PREFORK_MODULE_START_SERVERS']}}
    MinSpareServers     {{env['APACHE_MPM_PREFORK_MODULE_MIN_SPARE_SERVERS']}}
    MaxSpareServers     {{env['APACHE_MPM_PREFORK_MODULE_MAX_SPARE_SERVERS']}}
    MaxClients          {{env['APACHE_MPM_PREFORK_MODULE_MAX_CLIENTS']}}
    MaxRequestsPerChild {{env['APACHE_MPM_PREFORK_MODULE_MAX_REQUESTS_PER_CHILD']}}
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet