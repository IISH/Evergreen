<?xml version='1.0'?>

<!--
Example opensrf config file for OpenILS
vim:et:ts=4:sw=4:
-->

<opensrf version='0.0.3'>

    <default>

        <!-- unless otherwise overidden, use this locale -->
        <default_locale>en-US</default_locale>

        <dirs>
            <log>{{env['OPENILS_SYSDIR']}}/var/log</log> <!-- unix::server log files -->
            <sock>{{env['OPENILS_SYSDIR']}}/var/lock</sock> <!-- unix::server sock files -->
            <pid>{{env['OPENILS_SYSDIR']}}/var/run</pid>
            <xsl>{{env['OPENILS_SYSDIR']}}/var/xsl</xsl>
            <script>{{env['OPENILS_SYSDIR']}}/var</script>
            <script_lib>{{env['OPENILS_SYSDIR']}}/var</script_lib>
            <templates>{{env['OPENILS_SYSDIR']}}/var/templates</templates>
        </dirs>

        {%- for setting in env['OPENILS_CUSTOM_SETTINGS'].split() %}
        {{setting}}
        {%- endfor %}

        <!-- global data visibility settings -->
        <share>
            <user>
                <!-- Set to "true" to require patron opt-in for foreign (non-home_ou) transactions -->
                <opt_in>false</opt_in>
            </user>
        </share>

        <IDL>{{env['OPENILS_SYSDIR']}}/conf/fm_IDL.xml</IDL> <!-- top level IDL file -->
        <IDL2js>fm_IDL2js.xsl</IDL2js> <!-- IDL JS XSLT -->


        <server_type>prefork</server_type> <!-- net::server type -->

        <ils_events>{{env['OPENILS_SYSDIR']}}/var/data/ils_events.xml</ils_events> <!-- ILS events description file -->

        <email_notify> <!-- this will eventually move into the notifications section below... -->
            <!-- global email notification settings -->
            <template>{{env['OPENILS_SYSDIR']}}/var/data/hold_notification_template.example</template>
            <smtp_server>{{env['OPENILS_SMTP_SERVER']}}</smtp_server>

            <!--
            in most cases, this is overridden by location
            specific config settings.  this is just the default
            -->
            <sender_address>{{env['OPENILS_SENDER_ADDRESS']}}</sender_address>
        </email_notify>


        <notifications>
            <!-- global mail server settings -->
            <smtp_server>{{env['OPENILS_SMTP_SERVER']}}</smtp_server>
            <sender_address>{{env['OPENILS_SENDER_ADDRESS']}}</sender_address>

            <!-- global telephony (asterisk) settings -->
            <telephony>
                <!-- replace all values below when telephony server is configured -->
                <enabled>0</enabled>
                <driver>SIP</driver>    <!-- SIP (default) or multi -->
                <channels>              <!-- explicit list of channels used if multi -->
                    <!-- A channel specifies technology/resource -->
                    <channel>Zap/1</channel>
                    <channel>Zap/2</channel>
                    <channel>IAX/user:secret@widgets.biz</channel>
                </channels>
                <host>localhost</host>
                <port>10080</port>
                <user>evergreen</user>
                <pw>evergreen</pw>
                <!--
                    The overall composition of callfiles is determined by the
                    relevant template, but this section can be invoked for callfile
                    configs common to all outbound calls.
                    callfile_lines will be inserted into ALL generated callfiles
                    after the Channel line.  This content mat be overridden
                    (in whole) by the org unit setting callfile_lines.
                    Warning: Invalid syntax may break ALL outbound calls.
                -->
                <!-- <callfile_lines>
                    MaxRetries: 3
                    RetryTime: 60
                    WaitTime: 30
                    Archive: 1
                    Extension: 10
                </callfile_lines> -->
            </telephony>

            <!-- Overdue notices: DEPRECATED in 2.0 in favour of Action/Trigger Notifications -->
            <overdue>

                <!-- optionally, you can define a sender address per notice type -->
                <sender_address>{{env['OPENILS_SENDER_ADDRESS']}}</sender_address>

                <!-- The system can generate an XML file of overdue notices.  This is the
                    directory where they are stored.  Files are named overdue.YYYY-MM-DD.xml -->
            <notice_dir>{{env['OPENILS_SYSDIR']}}/var/data/overdue</notice_dir>
            <combined_template>{{env['OPENILS_SYSDIR']}}/var/data/templates/overdue_combined_xml.example</combined_template>

            <notice>
                <!-- Notify at 7 days overdue -->
                <notify_interval>7 days</notify_interval>
                <!-- Options include always, noemail, and never.  'noemail' means a notice
                     will be appended to the notice file only if the patron has no valid email address.  -->
                <file_append>noemail</file_append>
                <!-- do we attempt email notification? -->
                <email_notify>false</email_notify>
                <!-- notice template file -->
                <email_template>{{env['OPENILS_SYSDIR']}}/var/data/templates/overdue_7day.example</email_template>
            </notice>
        </overdue>

        <!-- Courtesy notices: DEPRECATED in 2.0 in favour of Action/Trigger Notifications -->
        <predue>
            <notice>
                <!-- All circulations that circulate between 5 and 13 days -->
                <circ_duration_range>
                    <from>5 days</from>
                    <to>13 days</to>
                </circ_duration_range>
                <!-- notify at 1 day before the due date -->
                <notify_interval>1 day</notify_interval>
                <file_append>false</file_append>
                <email_notify>false</email_notify>
                <email_template>{{env['OPENILS_SYSDIR']}}/var/data/templates/predue_1day.example</email_template>
            </notice>
        </predue>
      </notifications>

        <!-- Settings for the hold targeter cron job -->
        <hold_targeter>
            <!-- number of parallel processes to use during hold targeting;
                 increasing can speed up (re)targeting a large number of
                 hold requests, but with diminishing returns after a point;
                 if increasing this value, it is recommend to do so slowly
            -->
            <parallel>1</parallel>
        </hold_targeter>

        <!-- Settings for the fine generator cron job -->
        <fine_generator>
            <!-- number of parallel processes to use during fine generation -->
            <parallel>1</parallel>
        </fine_generator>

        <reporter>
            <!--
            Settings for the reporter daemon process
            -->
            <setup>
                <base_uri>{{env['OPENILS_PROXY']}}/reporter</base_uri>
                <database>
                    <driver>Pg</driver>
                    <host>{{env['OPENILS_DATABASE_MIRROR_HOST']}}</host>
                    <port>{{env['OPENILS_DATABASE_MIRROR_PORT']}}</port>
                    <db>{{env['OPENILS_DATABASE_MIRROR_DB']}}</db>
                    <user>{{env['OPENILS_DATABASE_MIRROR_USER']}}</user>
                    <pw>{{env['OPENILS_DATABASE_MIRROR_PW']}}</pw>
                </database>
                <state_store>
                    <driver>Pg</driver>
                    <host>{{env['OPENILS_DATABASE_MASTER_HOST']}}</host>
                    <port>{{env['OPENILS_DATABASE_MASTER_PORT']}}</port>
                    <db>{{env['OPENILS_DATABASE_MASTER_DB']}}</db>
                    <user>{{env['OPENILS_DATABASE_MASTER_USER']}}</user>
                    <pw>{{env['OPENILS_DATABASE_MASTER_PW']}}</pw>
                </state_store>
                <files>
                    <!-- successful report outputs go here -->
                    <output_base>{{env['OPENILS_SYSDIR']}}/var/web/reporter</output_base>
                    <success_template>{{env['OPENILS_SYSDIR']}}/var/data/report-success</success_template>
                    <fail_template>{{env['OPENILS_SYSDIR']}}/var/data/report-fail</fail_template>
                </files>
            </setup>
        </reporter>



        <xml-rpc>
            <!-- XML-RPC gateway.  Do NOT publish unprotected services here -->
            <allowed_services>
                <!-- list of published services -->
                {%- for service in env['OPENILS_ALLOWED_SERVICES'].split() %}
                <service>{{service}}</service>
                {%- endfor %}
            </allowed_services>
        </xml-rpc>

        <!--
        Once upon a time, Z39.50 servers were defined here. As of Evergreen 2.2,
        they are now defined in the database. See the Release Notes for
        instructions on mapping the old XML entries to database tables.
        -->

        <added_content>
            <!-- load the OpenLibrary added content module -->
            <module>OpenILS::WWW::AddedContent::OpenLibrary</module>

            <!--
            Max number of seconds to wait for an added content request to
            return data.  Data not returned within the timeout is considered
            a failure.

            Note that the pool of Apache processes used by the AddedContent
            module is the same pool used by core Evergreen processes such as
            search, circulation, etc. Therefore, the higher you set this
            timeout value, the more likely you are to run out of available
            Apache processes resulting in an accidental (or purposeful) denial
            of service - particularly if the added content server starts
            responding abnormally slowly.

            The safest option is to disable the AddedContent module completely,
            but 3 seconds is a compromise between the threat of a denial of
            service and the enhanced user experience offered by successful added
            content requests.
            -->
            <timeout>3</timeout>

            <!--
            After added content lookups have been disabled due to too many
            lookup failures, this is the amount of time to wait before
            we try again
            -->
            <retry_timeout>600</retry_timeout>

            <!--
            maximum number of consecutive lookup errors a given process can
            have before added content lookups are disabled for everyone
            -->
            <max_errors>15</max_errors>

            <!-- If a userid is required to access the added content.. -->
            <userid>MY_USER_ID</userid>

            <!--
            Base URL for Amazon added content fetching. Not needed by OpenLibrary
            <base_url>http://images.amazon.com/images/P/</base_url>
            -->

            <!--
            Segregating the details for ContentCafe out for easier use.  At some point, we
            may want to support multiple services at one time.
            -->
            <ContentCafe>
                <userid>MY_USER_ID</userid>
                <password>MY_PW</password>

                <!--
                Which order to put identifiers in.
                Default is "isbn,upc", ignoring currently unsupported issn.
                Should be all lowercase.
                Remove an identifier from the list to skip it.
                -->
                <identifier_order>isbn,upc</identifier_order>
            </ContentCafe>

            <!--

            You can add free-form settings here and they will be accessible
            within the added content module
            -->

        </added_content>

        <!-- Config section for acq_order_reader.pl script.
             It reads MARC order record files from disk (presumably
             an FTP destination) and pushes the order records into ACQ.
             THIS IS NOT EDI. -->
        <acq_order_reader>

            <!-- Root directory for all FTP'd ACQ order record files .
                 If the script is configured to talk to a remote acq server,
                 this directory has to be a read/write NFS share.  -->
            <base_dir>{{env['OPENILS_SYSDIR']}}/var/data/acq_orders/</base_dir>

            <!-- any files found in the shared subdir must be inspected
                 (e.g. file name prefix) to determine the provider. -->
            <shared_subdir>ALL</shared_subdir><!-- SUPPORT PENDING -->

            <!-- providers that don't provide a mechanism to inspect the file
                 have to push their files to provider-specific locations -->
            <provider>
                <ordering_agency>BR1</ordering_agency> <!-- who gets/manages the order -->
                <provider_code>BAB</provider_code>
                <provider_owner>CONS</provider_owner>  <!-- provider provider_owner; org unit shortname -->
                <subdir>CONS-BAB</subdir> <!-- file directory;  full path = base_dir + subdir -->
                <activate_po>false</activate_po> <!-- activate PO at upload? -->
                <vandelay>
                    <import_no_match>true</import_no_match>
                    <!-- Most Vandelay options are supported.  For bools, use true/false.
                        match_quality_ratio
                        match_set
                        bib_source
                        merge_profile
                        create_assets
                        import_no_match
                        auto_overlay_exact
                        auto_overlay_1match
                        auto_overlay_best_match
                    -->
                </vandelay>
            </provider>

            <!-- Add more as needed...
            <provider>
                ...
            </provider>
            -->

        </acq_order_reader>


        <!-- no apps are enabled globally by default -->
        <activeapps/>

        <cache>
            <!-- memcache servers -->
            <global>
                <servers>
                    <server>{{env['OPENILS_MEMCACHED_SERVER']}}</server>
                </servers>
                <max_cache_time>86400</max_cache_time>
            </global>
            <anon>
                <!-- anonymous cache.  currently, primarily used for web session caching -->
                <servers>
                    <server>{{env['OPENILS_MEMCACHED_SERVER']}}</server>
                </servers>
                <max_cache_time>1800</max_cache_time>
                <!-- maximum size of a single cache entry / default = 100k-->
                <max_cache_size>102400</max_cache_size>
            </anon>
        </cache>

        <apps>
            <!-- Acquisitions server -->
            <open-ils.acq>
                <!-- how long to wait between stateful requests before the child process re-joins the pool -->
                <keepalive>5</keepalive>
                <!-- true if this service support stateless requests -->
                <stateless>1</stateless>
                <!-- implementation language -->
                <language>perl</language>
                <!-- name of the library that implements this application -->
                <implementation>OpenILS::Application::Acq</implementation>
                <!-- maximum OpenSRF REQUEST within a stateful connection -->
                <max_requests>100</max_requests>
                <unix_config>
                    <!--
                    maximum number of top level requests coming to
                    this child before the child is recycled
                    -->
                    <max_requests>100</max_requests>
                    <!-- min children to fork -->
                    <min_children>1</min_children>
                    <!-- max possible children to fork -->
                    <max_children>15</max_children>
                    <!--
                    C forking implementation does not support
                    min/max idle children, but may in the future
                    -->

                    <!-- min idle children -->
                    <min_spare_children>1</min_spare_children>
                    <!-- max idle children -->
                    <max_spare_children>5</max_spare_children>
                    <!-- currently, only Perl uses the following 3 settings -->
                    <unix_sock>open-ils.acq_unix.sock</unix_sock>
                    <unix_pid>open-ils.acq_unix.pid</unix_pid>
                    <unix_log>open-ils.acq_unix.log</unix_log>
                </unix_config>
            </open-ils.acq>

            <!-- Authentication server -->
            <open-ils.auth>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>c</language>
                <implementation>oils_auth.so</implementation>
                <unix_config>
                    <max_requests>1000</max_requests>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <!-- defined app-specific settings here -->
                    <default_timeout>
                        <!-- default login timeouts based on login type -->
                        <opac>420</opac>
                        <staff>7200</staff>
                        <temp>300</temp>
                        <persist>2 weeks</persist>
                    </default_timeout>
                    <auth_limits>
                        <seed>30</seed> <!-- amount of time a seed request is valid for -->
                        <block_time>90</block_time> <!-- amount of time since last auth or seed request to save failure counts -->
                        <block_count>10</block_count> <!-- number of failures before blocking access -->
                    </auth_limits>
                </app_settings>
            </open-ils.auth>

            <!-- Authentication proxy server -->
            <open-ils.auth_proxy>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::AuthProxy</implementation>
                <max_requests>93</max_requests>

                <unix_config>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.auth-proxy_unix.log</unix_log>
                    <unix_sock>open-ils.auth-proxy_unix.sock</unix_sock>
                    <unix_pid>open-ils.auth-proxy_unix.pid</unix_pid>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>

                <app_settings>
                    <!-- 'enabled' is the master switch; set to 'true' to enable proxied logins -->
                    <enabled>{{env['OPENILS_AUTH_PROXY_ENABLED']}}</enabled>
                    <authenticators>{{env['OPENILS_AUTHENTICATORS']}}</authenticators>
                </app_settings>
            </open-ils.auth_proxy>

            <!-- Generic search server -->
            <open-ils.search>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Search</implementation>
                <max_requests>93</max_requests>
                <unix_config>
                    <unix_sock>open-ils.search_unix.sock</unix_sock>
                    <unix_pid>open-ils.search_unix.pid</unix_pid>
                    <unix_log>open-ils.search_unix.log</unix_log>

                    <max_requests>1000</max_requests>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <marc_html_xsl>oilsMARC21slim2HTML.xsl</marc_html_xsl>
                    <marc_html_xsl_slim>oilsMARC21slim2HTMLslim.xsl</marc_html_xsl_slim>

                    <spelling_dictionary>
                        <!-- 
                            Optionally configure different dictionaries depending on search context.  
                            If no dictionaries are defined, the default Aspell dictionary is used.
                        -->
                        <!--
                        <default>{{env['OPENILS_SYSDIR']}}/var/data/default_dict.txt</default>
                        <title>{{env['OPENILS_SYSDIR']}}/var/data/title_dict.txt</title>
                        <author>{{env['OPENILS_SYSDIR']}}/var/data/author_dict.txt</author>
                        <subject>{{env['OPENILS_SYSDIR']}}/var/data/subject_dict.txt</subject>
                        <series>{{env['OPENILS_SYSDIR']}}/var/data/series_dict.txt</series>
                        -->
                    </spelling_dictionary>

                    <!-- Default to using staged search -->
                    <use_staged_search>true</use_staged_search>

                    <!--
                        For staged search, we estimate hits based on inclusion or exclusion.

                        Valid settings:
                            inclusion - visible ratio on superpage
                            exclusion - excluded ratio on superpage
                            delete_adjusted_inclusion - included ratio on superpage, ratio adjusted by deleted count
                            delete_adjusted_exclusion - excluded ratio on superpage, ratio adjusted by deleted count

                        Under normal circumstances, inclusion is the best strategy, and both delete_adjusted variants
                        will return the same value +/- 1.  The exclusion strategy is the original, and works well
                        when there are few deleted or excluded records, in other words, when the superpage is not
                        sparsely populated with visible records.
                    -->
                    <estimation_strategy>inclusion</estimation_strategy>

                    <!--
                        Evergreen uses a cover density algorithm for calculating relative ranking of matches.  There
                        are several tuning parameters and options available.  By default, no document length normalization
                        is applied.  From the Postgres documentation on ts_rank_cd() (the function used by Evergreen):

                            Since a longer document has a greater chance of containing a query term it is reasonable 
                            to take into account document size, e.g., a hundred-word document with five instances of 
                            a search word is probably more relevant than a thousand-word document with five instances. 
                            Both ranking functions take an integer normalization option that specifies whether and how 
                            a document's length should impact its rank. The integer option controls several behaviors, 
                            so it is a bit mask: you can specify one or more behaviors using | (for example, 2|4).

                                0 (the default) ignores the document length

                                1 divides the rank by 1 + the logarithm of the document length

                                2 divides the rank by the document length

                                4 divides the rank by the mean harmonic distance between extents (this is implemented only by ts_rank_cd)

                                8 divides the rank by the number of unique words in document

                                16 divides the rank by 1 + the logarithm of the number of unique words in document

                                32 divides the rank by itself + 1

                            If more than one flag bit is specified, the transformations are applied in the order listed.

                            It is important to note that the ranking functions do not use any global information, so it 
                            is impossible to produce a fair normalization to 1% or 100% as sometimes desired. Normalization 
                            option 32 (rank/(rank+1)) can be applied to scale all ranks into the range zero to one, but of 
                            course this is just a cosmetic change; it will not affect the ordering of the search results.

                        In Evergreen, these options are set via search modifiers.  The modifiers are mapped in the
                        following way:

                            * #CD_logDocumentLength  => 1  :: rank / (1 + LOG(total_word_count))   :: Longer documents slightly less relevant
                            * #CD_documentLength     => 2  :: rank / total_word_count              :: Longer documents much less relevant
                            * #CD_meanHarmonic       => 4  :: Word Proximity                       :: Greater matched-word distance is less relevant
                            * #CD_uniqueWords        => 8  :: rank / unique_word_count             :: Documents with repeated words much less relevant
                            * #CD_logUniqueWords     => 16 :: rank / (1 + LOG(unique_word_count))  :: Documents with repeated words slightly less relevant
                            * #CD_selfPlusOne        => 32 :: rank / (1 + rank)                    :: Cosmetic normalization of rank value between 0 and 1

                        Adding one or more of these to the default_CD_modifiers list will cause all searches that use QueryParser to apply them.
                    -->
                    <default_CD_modifiers>#CD_documentLength #CD_meanHarmonic #CD_uniqueWords</default_CD_modifiers>

                    <!--
                        default_preferred_language
                            Set the global, default preferred languange
                    -->
                    <default_preferred_language>eng</default_preferred_language>

                    <!--
                        default_preferred_language_weight
                            Set the weight (higher is "better") for the preferred language. Comment out to remove all lanuage weighting by default.
                    -->
                    <default_preferred_language_weight>5</default_preferred_language_weight>

                    <!-- Baseline number of records to check for hit estimation. -->
                    <superpage_size>1000</superpage_size>

                    <!-- How many superpages to consider for searching overall. -->
                    <max_superpages>10</max_superpages>

                    <!-- zip code database file -->
                    <!--<zips_file>{{env['OPENILS_SYSDIR']}}/var/data/zips.txt</zips_file>-->
                </app_settings>
            </open-ils.search>

            <!-- server for accessing user info -->
            <open-ils.actor>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Actor</implementation>
                <max_requests>93</max_requests>
                <unix_config>
                    <unix_sock>open-ils.actor_unix.sock</unix_sock>
                    <unix_pid>open-ils.actor_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.actor_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <!-- set this to 'true' to have barcode search also search patron records by unique ID -->
                <app_settings>
                    <id_as_barcode>false</id_as_barcode>
                </app_settings>

            </open-ils.actor>

            <open-ils.booking>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Booking</implementation>
                <max_requests>199</max_requests>
                <unix_config>
                    <unix_sock>open-ils.booking_unix.sock</unix_sock>
                    <unix_pid>open-ils.booking_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.booking_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                </app_settings>
            </open-ils.booking>

            <open-ils.cat>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Cat</implementation>
                <max_requests>199</max_requests>
                <unix_config>
                    <unix_sock>open-ils.cat_unix.sock</unix_sock>
                    <unix_pid>open-ils.cat_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.cat_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <marctemplates>
                        {%- for marctemplate in env['OPENILS_MARCTEMPLATES'].split() %}
                        <{{marctemplate}}>{{env['OPENILS_SYSDIR']}}/var/templates/marc/{{marctemplate}}.xml</{{marctemplate}}>
                        {%- endfor %}
                    </marctemplates>
                </app_settings>
            </open-ils.cat>

            <open-ils.supercat>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::SuperCat</implementation>
                <max_requests>199</max_requests>
                <unix_config>
                    <unix_sock>open-ils.supercat_unix.sock</unix_sock>
                    <unix_pid>open-ils.supercat_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.supercat_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
            </open-ils.supercat>

            <open-ils.oai>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::OAI</implementation>
                <max_requests>199</max_requests>
                <unix_config>
                    <unix_sock>open-ils.oai_unix.sock</unix_sock>
                    <unix_pid>open-ils.oai_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.oai_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>5</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>2</max_spare_children>
                </unix_config>
                <app_settings>{{env['OPENILS_APPS_OAI']}}</app_settings>
            </open-ils.oai>

            <open-ils.handle>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Handle</implementation>
                <max_requests>199</max_requests>
                <unix_config>
                    <unix_sock>open-ils.handle_unix.sock</unix_sock>
                    <unix_pid>open-ils.handle_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.handle_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>2</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>2</max_spare_children>
                </unix_config>
                <app_settings>
                    <endpoint>{{env['OPENILS_APPS_HANDLE_ENDPOINT']}}</endpoint>
                    <authorization>{{env['OPENILS_APPS_HANDLE_AUTHORIZATION']}}</authorization>
                    <bind_url_available>{{env['OPENILS_APPS_HANDLE_BIND_URL_AVAILABLE']}}</bind_url_available>
                    <bind_url_deleted>{{env['OPENILS_APPS_HANDLE_BIND_URL_DELETED']}}</bind_url_deleted>
                    <timeout></timeout>
                </app_settings>
            </open-ils.handle>

            <open-ils.batch-update>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::BatchUpdate</implementation>
                <max_requests>199</max_requests>
                <unix_config>
                    <unix_sock>open-ils.batch-update_unix.sock</unix_sock>
                    <unix_pid>open-ils.batch-update_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.batch-update_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>2</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>2</max_spare_children>
                </unix_config>
                <app_settings>
                </app_settings>
            </open-ils.batch-update>

            <open-ils.batch-enrich>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::BatchEnrich</implementation>
                <max_requests>199</max_requests>
                <unix_config>
                    <unix_sock>open-ils.batch-enrich_unix.sock</unix_sock>
                    <unix_pid>open-ils.batch-enrich_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.batch-enrich_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>2</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>2</max_spare_children>
                </unix_config>
                <app_settings>
                </app_settings>
            </open-ils.batch-enrich>

            <!-- server for accessing user info -->
            <open-ils.trigger>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Trigger</implementation>
                <max_requests>93</max_requests>
                <unix_config>
                    <unix_sock>open-ils.trigger_unix.sock</unix_sock>
                    <unix_pid>open-ils.trigger_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.trigger_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <!-- number of parallel open-ils.trigger processes to use for collection and reaction -->
                    <!--
                    <parallel>
                        <collect>3</collect>
                        <react>3</react>
                    </parallel>
                    -->
                </app_settings>
            </open-ils.trigger>

            <open-ils.url_verify>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::URLVerify</implementation>
                <max_requests>199</max_requests>
                <unix_config>
                    <unix_sock>open-ils.url_verify_unix.sock</unix_sock>
                    <unix_pid>open-ils.url_verify_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.url_verify_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <user_agent>Evergreen %s Link Checker</user_agent>
                </app_settings>
            </open-ils.url_verify>

            <opensrf.math>
                <keepalive>3</keepalive>
                <stateless>1</stateless>
                <language>c</language>
                <implementation>osrf_math.so</implementation>
                <unix_config>
                    <unix_sock>opensrf.math_unix.sock</unix_sock>
                    <unix_pid>opensrf.math_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>opensrf.math_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
            </opensrf.math>

            <opensrf.dbmath>
                <keepalive>3</keepalive>
                <stateless>1</stateless>
                <language>c</language>
                <implementation>osrf_dbmath.so</implementation>
                <unix_config>
                    <max_requests>1000</max_requests>
                    <unix_log>opensrf.dbmath_unix.log</unix_log>
                    <unix_sock>opensrf.dbmath_unix.sock</unix_sock>
                    <unix_pid>opensrf.dbmath_unix.pid</unix_pid>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children> 
                    <max_spare_children>5</max_spare_children>
                </unix_config>
            </opensrf.dbmath>

            <open-ils.penalty>
                <keepalive>3</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Penalty</implementation>
                <max_requests>99</max_requests>
                <unix_config>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.penalty_unix.log</unix_log>
                    <unix_sock>open-ils.penalty_unix.sock</unix_sock>
                    <unix_pid>open-ils.penalty_unix.pid</unix_pid>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <patron_penalty>penalty/patron_penalty.js</patron_penalty>
                    <script_path>{{env['OPENILS_SYSDIR']}}/lib/javascript</script_path>
                    <script_path>{{env['OPENILS_SYSDIR']}}/var</script_path>
                    <script_path>{{env['OPENILS_SYSDIR']}}/var/catalog</script_path>
                </app_settings>
            </open-ils.penalty>

            <open-ils.justintime>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::JustInTime</implementation>
                <max_requests>199</max_requests>
                <unix_config>
                    <unix_sock>open-ils.justintime_unix.sock</unix_sock>
                    <unix_pid>open-ils.justintime_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.justintime_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                </app_settings>
            </open-ils.justintime>

            <open-ils.circ>
                <keepalive>3</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Circ</implementation>
                <max_requests>99</max_requests>
                <unix_config>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.circ_unix.log</unix_log>
                    <unix_sock>open-ils.circ_unix.sock</unix_sock>
                    <unix_pid>open-ils.circ_unix.pid</unix_pid>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children> 
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <notify_hold>
                        <email>false</email> <!-- set to false to disable hold notice emails -->
                    </notify_hold>

                    <!-- circulation policy scripts -->
                    <script_path>{{env['OPENILS_SYSDIR']}}/lib/javascript</script_path>
                    <script_path>{{env['OPENILS_SYSDIR']}}/var</script_path>
                    <script_path>{{env['OPENILS_SYSDIR']}}/var/catalog</script_path>
                    <legacy_script_support>false</legacy_script_support>
                    <scripts> 
                        <circ_permit_patron>circ/circ_permit_patron.js</circ_permit_patron>
                        <circ_permit_copy>circ/circ_permit_copy.js</circ_permit_copy>
                        <circ_duration>circ/circ_duration.js</circ_duration>
                        <circ_recurring_fines>circ/circ_recurring_fines.js</circ_recurring_fines>
                        <circ_max_fines>circ/circ_max_fines.js</circ_max_fines>
                        <circ_permit_renew>circ/circ_permit_renew.js</circ_permit_renew>
                        <circ_permit_hold>circ/circ_permit_hold.js</circ_permit_hold>
                    </scripts>               

                </app_settings>
            </open-ils.circ>

            <open-ils.storage>
                <keepalive>10</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Storage</implementation>
                <unix_config>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.storage_unix.log</unix_log>
                    <unix_sock>open-ils.storage_unix.sock</unix_sock>
                    <unix_pid>open-ils.storage_unix.pid</unix_pid>
                    <min_children>1</min_children>
                    <max_children>10</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <script_path>{{env['OPENILS_SYSDIR']}}/lib/javascript/</script_path>
                    <script_path>{{env['OPENILS_SYSDIR']}}/var/catalog/</script_path>
                    <scripts>
                        <biblio_fingerprint>biblio_fingerprint.js</biblio_fingerprint>
                    </scripts>
                    <databases>
                        <driver>Pg</driver>
                        <database>
                            <type>master</type>
                            <weight>2</weight>
                            <user>{{env['OPENILS_DATABASE_MASTER_USER']}}</user>
                            <host>{{env['OPENILS_DATABASE_MASTER_HOST']}}</host>
                            <port>{{env['OPENILS_DATABASE_MASTER_PORT']}}</port>
                            <pw>{{env['OPENILS_DATABASE_MASTER_PW']}}</pw>
                            <db>{{env['OPENILS_DATABASE_MASTER_DB']}}</db>
                            <client_encoding>UTF-8</client_encoding>
                        </database>
                    </databases>
                </app_settings>
            </open-ils.storage>

            <open-ils.cstore>
                <keepalive>6</keepalive>
                <stateless>1</stateless>
                <language>C</language>
                <implementation>oils_cstore.so</implementation>
                <unix_config>
                    <unix_log>open-ils.cstore_unix.log</unix_log>
                    <max_requests>1000</max_requests>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <max_query_recursion>100</max_query_recursion>
                    <driver>pgsql</driver>
                    <database>
                            <type>master</type>
                            <weight>2</weight>
                            <user>{{env['OPENILS_DATABASE_MASTER_USER']}}</user>
                            <host>{{env['OPENILS_DATABASE_MASTER_HOST']}}</host>
                            <port>{{env['OPENILS_DATABASE_MASTER_PORT']}}</port>
                            <pw>{{env['OPENILS_DATABASE_MASTER_PW']}}</pw>
                            <db>{{env['OPENILS_DATABASE_MASTER_DB']}}</db>
                            <client_encoding>UTF-8</client_encoding>
                        </database>
                </app_settings>
            </open-ils.cstore>

            <open-ils.pcrud>
                <keepalive>6</keepalive>
                <migratable>1</migratable>
                <stateless>1</stateless>
                <language>C</language>
                <implementation>oils_pcrud.so</implementation>

                <unix_config>
                    <unix_log>open-ils.pcrud.log</unix_log>
                    <unix_sock>open-ils.pcrud.sock</unix_sock>
                    <unix_pid>open-ils.pcrud.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>

                <app_settings>
                    <IDL>{{env['OPENILS_SYSDIR']}}/conf/fm_IDL.xml</IDL>
                    <driver>pgsql</driver>
                   <database>
                            <type>master</type>
                            <weight>2</weight>
                            <user>{{env['OPENILS_DATABASE_MASTER_USER']}}</user>
                            <host>{{env['OPENILS_DATABASE_MASTER_HOST']}}</host>
                            <port>{{env['OPENILS_DATABASE_MASTER_PORT']}}</port>
                            <pw>{{env['OPENILS_DATABASE_MASTER_PW']}}</pw>
                            <db>{{env['OPENILS_DATABASE_MASTER_DB']}}</db>
                            <client_encoding>UTF-8</client_encoding>
                        </database>
                </app_settings>
            </open-ils.pcrud>

            <open-ils.qstore>
                <keepalive>6</keepalive>
                <stateless>1</stateless>
                <language>C</language>
                <implementation>oils_qstore.so</implementation>
                <unix_config>
                    <max_requests>1000</max_requests>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <driver>pgsql</driver>
                    <database>
                            <type>master</type>
                            <weight>2</weight>
                            <user>{{env['OPENILS_DATABASE_MASTER_USER']}}</user>
                            <host>{{env['OPENILS_DATABASE_MASTER_HOST']}}</host>
                            <port>{{env['OPENILS_DATABASE_MASTER_PORT']}}</port>
                            <pw>{{env['OPENILS_DATABASE_MASTER_PW']}}</pw>
                            <db>{{env['OPENILS_DATABASE_MASTER_DB']}}</db>
                            <client_encoding>UTF-8</client_encoding>
                        </database>
                </app_settings>
            </open-ils.qstore>

            <opensrf.settings>
                <keepalive>1</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenSRF::Application::Settings</implementation>
                <max_requests>17</max_requests>
                <unix_config>
                    <unix_sock>opensrf.settings_unix.sock</unix_sock>
                    <unix_pid>opensrf.settings_unix.pid</unix_pid>
                    <max_requests>300</max_requests>
                    <unix_log>opensrf.settings_unix.log</unix_log>
                    <min_children>5</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>3</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
            </opensrf.settings>

            <open-ils.collections>
                <keepalive>3</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Collections</implementation>
                <max_requests>17</max_requests>
                <unix_config>
                    <unix_sock>open-ils.collections_unix.sock</unix_sock>
                    <unix_pid>open-ils.collections_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.collections_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>10</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <!-- batch_file_dir must be a protected, web-accessible, shared directory -->
                    <batch_file_dir>{{env['OPENILS_SYSDIR']}}/var/web/collections</batch_file_dir>
                </app_settings>
            </open-ils.collections>

            <open-ils.reporter>
                <keepalive>3</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Reporter</implementation>
                <max_requests>99</max_requests>
                <unix_config>
                    <unix_sock>open-ils.reporter_unix.sock</unix_sock>
                    <unix_pid>open-ils.reporter_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.reporter_unix.log</unix_log>
                    <min_children>1</min_children>
                    <max_children>10</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
            </open-ils.reporter>

            <open-ils.reporter-store>
                <keepalive>6</keepalive>
                <stateless>1</stateless>
                <language>C</language>
                <implementation>oils_rstore.so</implementation>
                <unix_config>
                    <max_requests>400</max_requests>
                    <min_children>1</min_children>
                    <max_children>10</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <driver>pgsql</driver>
                    <database>
                            <type>master</type>
                            <weight>2</weight>
                            <user>{{env['OPENILS_DATABASE_MASTER_USER']}}</user>
                            <host>{{env['OPENILS_DATABASE_MASTER_HOST']}}</host>
                            <port>{{env['OPENILS_DATABASE_MASTER_PORT']}}</port>
                            <pw>{{env['OPENILS_DATABASE_MASTER_PW']}}</pw>
                            <db>{{env['OPENILS_DATABASE_MASTER_DB']}}</db>
                            <client_encoding>UTF-8</client_encoding>
                        </database>
                </app_settings>
            </open-ils.reporter-store>

            <!-- resolver_type defaults to sfx but can also be cufts -->
           <open-ils.resolver>
               <keepalive>3</keepalive>
               <stateless>1</stateless>
               <language>perl</language>
               <implementation>OpenILS::Application::ResolverResolver</implementation>
               <max_requests>93</max_requests>
               <unix_config>
                  <unix_sock>open-ils.resolver_unix.sock</unix_sock>
                  <unix_pid>open-ils.resolver_unix.pid</unix_pid>
                  <max_requests>1000</max_requests>
                  <unix_log>open-ils.resolver_unix.log</unix_log>
                  <min_children>5</min_children>
                  <max_children>15</max_children>
                  <min_spare_children>3</min_spare_children>
                  <max_spare_children>5</max_spare_children>
               </unix_config>
               <app_settings>
                  <cache_timeout>86400</cache_timeout>
                  <request_timeout>10</request_timeout>
                  <default_url_base>http://path/to/sfx_or_cufts</default_url_base>
                  <resolver_type>sfx</resolver_type>
               </app_settings>
           </open-ils.resolver>

            <open-ils.permacrud>
               <keepalive>3</keepalive>
               <stateless>1</stateless>
               <language>perl</language>
               <implementation>OpenILS::Application::PermaCrud</implementation>
               <max_requests>17</max_requests>
               <unix_config>
                  <unix_sock>open-ils.permacrud_unix.sock</unix_sock>
                  <unix_pid>open-ils.permacrud_unix.pid</unix_pid>
                  <max_requests>1000</max_requests>
                  <unix_log>open-ils.permacrud_unix.log</unix_log>
                  <min_children>5</min_children>
                  <max_children>15</max_children>
                  <min_spare_children>3</min_spare_children>
                  <max_spare_children>5</max_spare_children>
               </unix_config>
            </open-ils.permacrud>

            <open-ils.fielder>
               <keepalive>3</keepalive>
               <stateless>1</stateless>
               <language>perl</language>
               <implementation>OpenILS::Application::Fielder</implementation>
               <max_requests>17</max_requests>
               <unix_config>
                  <unix_sock>open-ils.fielder_unix.sock</unix_sock>
                  <unix_pid>open-ils.fielder_unix.pid</unix_pid>
                  <max_requests>1000</max_requests>
                  <unix_log>open-ils.fielder_unix.log</unix_log>
                  <min_children>5</min_children>
                  <max_children>15</max_children>
                  <min_spare_children>3</min_spare_children>
                  <max_spare_children>5</max_spare_children>
               </unix_config>
            </open-ils.fielder>

            <open-ils.vandelay>
                <keepalive>5</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Vandelay</implementation>
                <max_requests>100</max_requests>
                <unix_config>
                    <unix_sock>vandelay_unix.sock</unix_sock>
                    <unix_pid>vandelay_unix.pid</unix_pid>
                    <unix_log>vandelay_unix.log</unix_log>
                    <max_requests>100</max_requests>
                    <min_children>1</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>1</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                    <databases>
                        <!-- temporary location for MARC import files.  
                            Files will be deleted after records are spooled.
                            *note:  in a multi-brick environment, this will need to
                            be on a write-able NFS share.  -->
                        <importer>/tmp</importer>
                    </databases>
                </app_settings>
            </open-ils.vandelay>

            <open-ils.serial>
                <keepalive>3</keepalive>
                <stateless>1</stateless>
                <language>perl</language>
                <implementation>OpenILS::Application::Serial</implementation>
                <max_requests>17</max_requests>
                <unix_config>
                    <unix_sock>open-ils.serial_unix.sock</unix_sock>
                    <unix_pid>open-ils.serial_unix.pid</unix_pid>
                    <max_requests>1000</max_requests>
                    <unix_log>open-ils.serial_unix.log</unix_log>
                    <min_children>5</min_children>
                    <max_children>15</max_children>
                    <min_spare_children>3</min_spare_children>
                    <max_spare_children>5</max_spare_children>
                </unix_config>
                <app_settings>
                </app_settings>
            </open-ils.serial>

        </apps>
    </default>

    <hosts>
        <{{env['FQDN'] or 'localhost'}}>
            <!-- ^-=- 
            Should match the fully qualified domain name of the host.

            On Linux, the output of the following command is authoritative:
            $ perl -MNet::Domain -e 'print Net::Domain::hostfqdn() . "\n";'

            To use 'localhost' instead, run osrf_control with the 'localhost' flag
            -->

            <activeapps>
                <!-- services hosted on this machine -->
                {%- for appname in env['OPENILS_ACTIVE_APPS'].split() %}
                <appname>{{appname}}</appname>
                {%- endfor %}
            </activeapps>
        </{{env['FQDN'] or 'localhost'}}>
    </hosts>

</opensrf>