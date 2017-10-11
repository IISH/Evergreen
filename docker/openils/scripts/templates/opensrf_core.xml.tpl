<?xml version="1.0"?>
<!--
    Do not change this file manually. It is created by a CI script.
    OpenSRF bootstrap configuration file for Evergreen
-->
<config>
    <!-- Options for <loglevel>: 0 None, 1 Error, 2 Warning, 3 Info, 4 debug -->
    <opensrf>
        <routers>

            <!-- define the list of routers our services will register with -->
            <router>
                <!--
                  This is the public router.  On this router, we only register
                  applications which should be accessible to everyone on the OpenSRF
                  network
                -->
                <name>router</name>
                <domain>{{env['OPENSRF_PUBLIC_DOMAIN']}}</domain>

                <services>
                    {%- for service in env['OPENSRF_SERVICES'].split() %}
                    <service>{{service}}</service>
                    {%- endfor %}
                </services>
            </router>

            <router>
                <!--
                  This is the private router.  All applications must register with
                  this router, so no explicit <services> section is required
                -->
                <name>router</name>
        <domain>{{env['OPENSRF_PRIVATE_DOMAIN']}}</domain>
            </router>
        </routers>

        <!-- Our domain should match that of the private router -->
    <domain>{{env['OPENSRF_PRIVATE_DOMAIN']}}</domain>
    <username>{{env['OPENSRF_PUBLIC_USER']}}</username>
    <passwd>{{env['OPENSRF_PUBLIC_PASSWD']}}</passwd>
    <port>5222</port>

        <!--
          Name of the router used on our private domain.
          This should match one of the <name> of the private router above.
         -->
        <router_name>router</router_name>

    <logfile>{{env['OPENILS_SYSDIR']}}/var/log/osrfsys.log</logfile>
    <!--
      <logfile>syslog</logfile>
      <syslog>local0</syslog>
      <actlog>local1</actlog>
     -->
    <loglevel>{{env['OPENSRF_LOGLEVEL'] or 3}}</loglevel>
    <settings_config>{{env['OPENILS_SYSDIR']}}/conf/opensrf.xml</settings_config>
  </opensrf>
  <!--
    The section between <gateway>...</gateway> is a standard OpenSRF C
    stack configuration file
  -->
  <gateway>
    <client>true</client>
    <router_name>router</router_name>

    <!-- The gateway connects to the public domain for security -->
    <domain>{{env['OPENSRF_PUBLIC_DOMAIN']}}</domain>

    <!-- This section will be soon deprecated for multi-domain mode... -->
    <services>
        {%- for service in env['OPENSRF_GATEWAY_SERVICES'].split() %}
        <service>{{service}}</service>
        {%- endfor %}
    </services>

    <!-- jabber login info -->
    <username>{{env['OPENSRF_PUBLIC_USER']}}</username>
    <passwd>{{env['OPENSRF_PUBLIC_PASSWD']}}</passwd>
    <port>5222</port>
    <loglevel>{{env['OPENSRF_LOGLEVEL'] or 3}}</loglevel>
    <logfile>{{env['OPENILS_SYSDIR']}}/var/log/gateway.log</logfile>

  </gateway>
  <!-- ======================================================================================== -->
  <routers>
    <router>
      <!-- public router -->
      <trusted_domains>
        <!--
          Allow private services to register with this router
          and public client to send requests to this router.
        -->
        <server>{{env['OPENSRF_PRIVATE_DOMAIN']}}</server>
        <!--
          Also allow private clients to send to the router so it
          can receive error messages
        -->
                <client>{{env['OPENSRF_PRIVATE_DOMAIN']}}</client>
                <client>{{env['OPENSRF_PUBLIC_DOMAIN']}}</client>

            </trusted_domains>

      <transport>
                <server>{{env['OPENSRF_PUBLIC_DOMAIN']}}</server>
        <port>5222</port>
                <unixpath>{{env['OPENILS_SYSDIR']}}/var/sock/unix_sock</unixpath>
          <username>{{env['OPENSRF_PRIVATE_USER']}}</username>
                <password>{{env['OPENSRF_PRIVATE_PASSWD']}}</password>
          <resource>router</resource>
          <connect_timeout>10</connect_timeout>
          <max_reconnect_attempts>5</max_reconnect_attempts>
      </transport>
            <logfile>{{env['OPENILS_SYSDIR']}}/var/log/public-router.log</logfile>
      <!--
        <logfile>syslog</logfile>
        <syslog>local2</syslog>
      -->
      <loglevel>{{env['OPENSRF_LOGLEVEL'] or 2}}</loglevel>
    </router>
    <router>
      <!-- private router -->
      <trusted_domains>
                <server>{{env['OPENSRF_PRIVATE_DOMAIN']}}</server>
        <!--
          Only clients on the private domain can send requests to this router
         -->
        <client>{{env['OPENSRF_PRIVATE_DOMAIN']}}</client>
      </trusted_domains>
      <transport>
                <server>{{env['OPENSRF_PRIVATE_DOMAIN']}}</server>
        <port>5222</port>
        <username>{{env['OPENSRF_PRIVATE_USER']}}</username>
                <password>{{env['OPENSRF_PRIVATE_PASSWD']}}</password>
        <resource>router</resource>
        <connect_timeout>10</connect_timeout>
        <max_reconnect_attempts>5</max_reconnect_attempts>
      </transport>
            <logfile>{{env['OPENILS_SYSDIR']}}/var/log/private-router.log</logfile>
      <!--
        <logfile>syslog</logfile>
        <syslog>local2</syslog>
      -->
      <loglevel>{{env['OPENSRF_LOGLEVEL'] or 2}}</loglevel>
    </router>
  </routers>
  <!-- ======================================================================================== -->

  <!-- Any methods which match any of these match_string node values will
       have their params redacted from lower-level input logging.
       Adjust these examples as needed. -->
  <shared>
    <log_protect>
        {%- for service in env['OPENSRF_LOG_PROTECT'].split() %}
        <match_string>{{service}}</match_string>
        {%- endfor %}
    </log_protect>
  </shared>
</config>
