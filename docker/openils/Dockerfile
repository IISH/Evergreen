# his image is for the Evergreen database
FROM ubuntu:16.04
MAINTAINER Lucien van Wouw <lwo@iisg.nl>
LABEL Description="This image is to build the Evergreen 2.12.6 base image" Version="1.0"

ENV EVERGREEN_VERSION=iish_master_rel_2_12_6 \
    OPENILS_HOME=/opt \
    OPENILS_SYSDIR=/openils \
    OPENSRF_HOME=/home/opensrf \
    OPENSRF_USER=opensrf \
    OPENSRF_SYSDIR=/openils \
    OPENSRF_VERSION=opensrf-2.5.2 \
    OSNAME=ubuntu-xenial \
    STAFF_CLIENT_STAMP_ID=rel_2_12_6

ENV APACHE_KEEP_ALIVE_TIMEOUT=1 \
    APACHE_MAX_KEEP_ALIVE_REQUESTS=100 \
    APACHE_MPM_PREFORK_MODULE_MAX_CLIENTS=150 \
    APACHE_MPM_PREFORK_MODULE_MAX_REQUESTS_PER_CHILD=10 \
    APACHE_MPM_PREFORK_MODULE_MAX_SPARE_SERVERS=10 \
    APACHE_MPM_PREFORK_MODULE_MIN_SPARE_SERVERS=5 \
    APACHE_MPM_PREFORK_MODULE_START_SERVERS=5 \
    APACHE_OFFLINE=false \
    APACHE_VERSION=24 \
    APACHE_WEB_TEMPLATE_PATH="" \
    OPENILS_ACTIVE_APPS="opensrf.settings \
        opensrf.math \
        opensrf.dbmath \
        open-ils.acq \
        open-ils.booking \
        open-ils.cat \
        open-ils.batch-update \
        open-ils.batch-enrich \
        open-ils.handle \
        open-ils.oai \
        open-ils.supercat \
        open-ils.search \
        open-ils.circ \
        open-ils.actor \
        open-ils.auth \
        open-ils.auth_proxy \
        open-ils.storage \
        open-ils.penalty \
        open-ils.justintime \
        open-ils.cstore \
        open-ils.collections \
        open-ils.reporter \
        open-ils.reporter-store \
        open-ils.permacrud \
        open-ils.pcrud \
        open-ils.trigger \
        open-ils.url_verify \
        open-ils.fielder \
        open-ils.vandelay \
        open-ils.serial" \
    OPENILS_ALLOWED_SERVICES="opensrf.math \
        opensrf.dbmath \
        open-ils.cat \
        open-ils.search \
        open-ils.circ \
        open-ils.actor \
        open-ils.auth \
        open-ils.auth_proxy \
        open-ils.collections \
        open-ils.justintime" \
    OPENILS_APPS_HANDLE_ENDPOINT=https://pid.socialhistoryservices.org:443/secure \
    OPENILS_APPS_HANDLE_AUTHORIZATION="bearer UUID" \
    OPENILS_APPS_HANDLE_BIND_URL_AVAILABLE=http://search.socialhistory.org/Record/% \
    OPENILS_APPS_HANDLE_BIND_URL_DELETED=http://search.socialhistory.org/Record/% \
    OPENILS_AUTH_PROXY_ENABLED=true \
    OPENILS_AUTHENTICATORS=<authenticator><name>native</name></authenticator>\
    OPENILS_CUSTOM_SETTINGS="<a>somevalue</a> \
        <b>somevalue</b>" \
    OPENILS_DATABASE_MASTER_DB=evergreen \
    OPENILS_DATABASE_MASTER_HOST=localhost \
    OPENILS_DATABASE_MASTER_PORT=5432 \
    OPENILS_DATABASE_MASTER_PW=evergreen \
    OPENILS_DATABASE_MASTER_USER=evergreen \
    OPENILS_DATABASE_MIRROR_DB=evergreen \
    OPENILS_DATABASE_MIRROR_HOST=localhost \
    OPENILS_DATABASE_MIRROR_PORT=5432 \
    OPENILS_DATABASE_MIRROR_PW=evergreen \
    OPENILS_DATABASE_MIRROR_USER=evergreen \
    OPENILS_MARCTEMPLATES="music_recordings \
        moving_image_collection \
        visual_collection \
        annual_report \
        book_collection \
        sound_recordings_collection \
        documentation \
        serial \
        photo_collection \
        archive \
        visual_document \
        music_recordings_collection \
        book \
        object \
        visual_document_landsberger \
        object_collection \
        article \
        visual_document_poster \
        sound_recordings \
        moving_image \
        visual_document_opland \
        serial_collection \
        visual_document_photo \
        poster_collection" \
    OPENILS_MEMCACHED_SERVER=memcached:11211 \
    OPENILS_APPS_OAI="<base_url>http://localhost/opac/extras/oai</base_url> \
        <repository_name>REPO</repository_name> \
        <admin_email>admin@localhost</admin_email> \
        <repository_identifier>localhost</repository_identifier> \
        <copies> \
          <a>owning_lib</a><b>circlib</b><c>location</c><j>callnumber</j><n>status</n><p>barcode</p> \
        </copies> \
        <barcode_filter>^[A-Za-z0-9]+</barcode_filter> \
        <status_filter>^Available$</status_filter>" \
    OPENILS_PROXY=https://localhost:443 \
    OPENILS_SENDER_ADDRESS=evergreen@localhost \
    OPENILS_SMTP_SERVER=localhost:25 \
    OPENSRF_GATEWAY_SERVICES="opensrf.math \
        opensrf.dbmath \
        open-ils.cat \
        open-ils.search \
        open-ils.circ \
        open-ils.actor \
        open-ils.auth \
        open-ils.auth_proxy \
        open-ils.collections \
        open-ils.reporter" \
    OPENSRF_LOG_PROTECT="open-ils.auth.authenticate.verify \
        open-ils.auth.authenticate.complete \
        open-ils.auth_proxy.login \
        open-ils.actor.patron.password_reset.commit \
        open-ils.acor.user.password \
        open-ils.actor.user.username \
        open-ils.actor.user.email \
        open-ils.actor.patron.update \
        open-ils.cstore.direct.actor.user.create \
        open-ils.cstore.direct.actor.user.update \
        open-ils.cstore.direct.actor.user.delete \
        open-ils.search.z3950.apply_credentials" \
    OPENSRF_PRIVATE_DOMAIN=private.realm \
    OPENSRF_PRIVATE_PASSWD=router \
    OPENSRF_PRIVATE_USER=router \
    OPENSRF_PUBLIC_DOMAIN=public.realm \
    OPENSRF_PUBLIC_PASSWD=opensrf \
    OPENSRF_PUBLIC_USER=opensrf \
    OPENSRF_SERVICES="opensrf.math \
        open-ils.actor \
        open-ils.acq \
        open-ils.auth \
        open-ils.auth_proxy \
        open-ils.batch \
        open-ils.booking \
        open-ils.cat \
        open-ils.circ \
        open-ils.collections \
        open-ils.fielder \
        open-ils.pcrud \
        open-ils.permacrud \
        open-ils.reporter \
        open-ils.search \
        open-ils.handle \
        open-ils.oai \
        open-ils.supercat \
        open-ils.vandelay \
        open-ils.serial"

# PREREQUISITES
RUN apt-get update && \
        apt-get -y install autoconf automake git libtool make python sudo wget # && \
        #wget "https://bootstrap.pypa.io/get-pip.py" -O get-pip.py && \
        #python get-pip.py && \
        #rm get-pip.py && \
        #pip install ninja2

ADD ./files /
ADD ./scripts $OPENILS_HOME/scripts


# USERS
RUN useradd -m $OPENSRF_USER ; \
    /bin/mkdir -p "${OPENSRF_HOME}" && \
    /bin/echo "export PATH=\$PATH:${OPENSRF_SYSDIR}/bin" > "${OPENSRF_HOME}/.bashrc" && \
    /bin/chown -R "$OPENSRF_USER":"$OPENSRF_USER" "${OPENSRF_HOME}" && \
    echo $OPENSRF_SYSDIR/lib > /etc/ld.so.conf.d/opensrf.conf && \
    ldconfig

# OPENSRF
RUN make_osname="${OSNAME}" && \
    make_options="--enable-python" && \
    installdir="${OPENSRF_SYSDIR}/install_opensrf/" && \
    rm -rf "$installdir" && \
    mkdir -p "$installdir" && \
    sysconfdir="${OPENSRF_SYSDIR}/conf" && \
    tar="${OPENSRF_VERSION}.tar.gz" && \
    url="https://evergreen-ils.org/downloads/${tar}" && \
    cd "$installdir" && \
    wget -O "$tar" "$url" && \
    tar -xaf "$tar" && \
    cd "$OPENSRF_VERSION" && \
    make -f src/extras/Makefile.install "$make_osname" && \
    autoreconf -i && \
    PATH=${OPENILS_SYSDIR}/bin:$PATH ./configure --prefix="$OPENSRF_SYSDIR" --sysconfdir="$sysconfdir" "$make_options" && \
    make && \
    make install && \
    chown -R "$OPENSRF_USER":"$OPENSRF_USER" "$OPENILS_SYSDIR"

# OPENILS
RUN make_osname="${OSNAME}" && \
    sysconfdir="${OPENILS_SYSDIR}/conf" && \
    tar="${EVERGREEN_VERSION}.tar.gz" && \
    url="https://github.com/IISH/Evergreen/archive/${tar}" && \
    installdir="${OPENILS_SYSDIR}/install_openils" && \
    rm -rf "$installdir" && \
    mkdir -p "$installdir" && \
    cd "$installdir" && \
    wget --no-check-certificate -O "$tar" "$url" && \
    tar -xaf "$tar" && \
    folder="${installdir}/Evergreen-${EVERGREEN_VERSION}" && \
    cd "$folder" && \
    autoreconf -i && \
    make -f Open-ILS/src/extras/Makefile.install "$make_osname" && \
    echo "/usr/local/lib/dbd" > /etc/ld.so.conf.d/eg.conf && \
    ldconfig && \
    make -f Open-ILS/src/extras/Makefile.install "$make_osname"-developer && \
    cd Open-ILS/web/js/ui/default/staff/ && \
    npm install && \
    sudo bower install --allow-root && \
    grunt all && \
    cd "$folder" && \
    PATH=${OPENILS_SYSDIR}/bin:$PATH ./configure --prefix="$OPENILS_SYSDIR" --sysconfdir="$sysconfdir" && \
    make && \
    make STAFF_CLIENT_STAMP_ID="$STAFF_CLIENT_STAMP_ID" install && \
    mv "Open-ILS/src/support-scripts" "${OPENILS_SYSDIR}/bin" && \
    ln -s "${OPENILS_SYSDIR}/var/web/xul/${STAFF_CLIENT_STAMP_ID}" "${OPENILS_SYSDIR}/var/web/xul/server" && \
    v="dojo-release-1.3.3" && \
    f="${v}.tar.gz" && \
    wget -O "$f" "http://download.dojotoolkit.org/release-1.3.3/${f}" && \
    tar -C "${OPENILS_SYSDIR}/var/web/js" -xzf "$f" && \
    cp -r "${OPENILS_SYSDIR}/var/web/js/${v}/"* "${OPENILS_SYSDIR}/var/web/js/dojo/". && \
    chown -R "$OPENSRF_USER":"$OPENSRF_USER" "$OPENILS_SYSDIR"

# DATABASE
RUN make_osname="${OSNAME}" && \
    sysconfdir="${OPENILS_SYSDIR}/conf" && \
    installdir="${OPENILS_SYSDIR}/install_postgres" && \
    rm -rf "$installdir" && \
    mkdir -p "$installdir" && \
    cd "$installdir" && \
    folder="${installdir}/Evergreen-${EVERGREEN_VERSION}" && \
    tar="${EVERGREEN_VERSION}.tar.gz" && \
    url="https://github.com/IISH/Evergreen/archive/${tar}" && \
    wget --no-check-certificate -O "$tar" "$url" && \
    tar -xaf "$tar" && \
    cd "Evergreen-${EVERGREEN_VERSION}" && \
    autoreconf -i && \
    make -f Open-ILS/src/extras/Makefile.install postgres-server-"$make_osname" && \
    useradd -m evergreen

ENTRYPOINT ["run.sh"]

CMD ["opensrf"]
