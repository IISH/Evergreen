<?xml version="1.0"?>
<!-- This file follows the standard bootstrap config file layout found in opensrf_core.xml -->
<srfsh>
  <router_name>router</router_name>
  <domain>{{env['OPENSRF_PRIVATE_DOMAIN']}}</domain>
  <username>{{env['OPENSRF_PUBLIC_USER']}}</username>
  <passwd>{{env['OPENSRF_PUBLIC_PASSWD']}}</passwd>
  <port>5222</port>
  <logfile>{{env['OPENILS_SYSDIR']}}/var/log/srfsh.log</logfile>
  <loglevel>4</loglevel>
  <client>true</client>
</srfsh>
