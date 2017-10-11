# To override, use config.sh


# The configuration files and their templates. Declared in CNF
# Keep the convention: CNF_KEY_$VARIABLE and TPL_KEY_$VARIABLE
readonly CNF_KEYS="APACHE APACHE_PORTS APACHE_SITE APACHE_STARTUP APACHE_VHOST EJABBERD FM_IDL MONITOR OPENSRF OPENSRF_CORE SRFSH"

readonly CNF_APACHE="/etc/apache2/apache2.conf"
TPL_APACHE="${OPENILS_HOME}/scripts/templates/apache2_${APACHE_VERSION}.conf.tpl"

readonly CNF_APACHE_PORTS="/etc/apache2/ports.conf"
TPL_APACHE_PORTS="${OPENILS_HOME}/scripts/templates/ports.conf.tpl"

readonly CNF_APACHE_SITE="/etc/apache2/sites-enabled/eg.conf"
TPL_APACHE_SITE="${OPENILS_HOME}/scripts/templates/eg_${APACHE_VERSION}.conf.tpl"

readonly CNF_APACHE_STARTUP="/etc/apache2/eg_startup"
TPL_APACHE_STARTUP="${OPENILS_HOME}/scripts/templates/eg_startup.tpl"

readonly CNF_APACHE_VHOST="/etc/apache2/eg_vhost.conf"
TPL_APACHE_VHOST="${OPENILS_HOME}/scripts/templates/eg_vhost_${APACHE_VERSION}.conf.tpl"

readonly CNF_APACHE_MODS_PREFORK="/etc/apache2/mods-available/mpm_prefork.conf"
TPL_APACHE_MODS_PREFORK="${OPENILS_HOME}/scripts/templates/mpm_prefork.conf.tpl"

readonly CNF_EJABBERD="/etc/ejabberd/ejabberd.cfg"
TPL_EJABBERD="${OPENILS_HOME}/scripts/templates/ejabberd.cfg"

readonly CNF_FM_IDL="${OPENILS_SYSDIR}/conf/fm_IDL.xml"
TPL_FM_IDL="${OPENILS_HOME}/scripts/templates/fm_IDL.xml"

readonly CNF_MONITOR="${OPENILS_SYSDIR}/bin/monitor.pl"
TPL_MONITOR="${OPENILS_HOME}/scripts/templates/monitor.pl.tpl"

readonly CNF_OPENSRF="${OPENILS_SYSDIR}/conf/opensrf.xml"
TPL_OPENSRF="${OPENILS_HOME}/scripts/templates/opensrf.xml.tpl"

readonly CNF_OPENSRF_CORE="${OPENILS_SYSDIR}/conf/opensrf_core.xml"
TPL_OPENSRF_CORE="${OPENILS_HOME}/scripts/templates/opensrf_core.xml.tpl"

readonly CNF_SRFSH="/home/${OPENSRF_USER}/.srfsh.xml"
TPL_SRFSH="${OPENILS_HOME}/scripts/templates/srfsh.xml.tpl"


readonly IP_ADDRESS=$(get_ipaddress)
readonly FQDN=$(get_fqdn)
readonly PYTHON_JINJA2="import os;
import sys;
import jinja2;
#os.environ['FQDN']='${FQDN}'
os.environ['IP_ADDRESS']='${IP_ADDRESS}'
sys.stdout.write(
    jinja2.Template
        (sys.stdin.read()
    ).render(env=os.environ))"