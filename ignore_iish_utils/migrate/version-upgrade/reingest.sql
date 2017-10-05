-- reingest
\qecho '\\t'
\qecho '\\o reingest_2.6_bib_recs.sql'
\qecho 'SELECT ''-- Grab current setting'';'
\qecho 'SELECT ''\\set force_reingest '' || enabled FROM config.internal_flag WHERE name = ''ingest.reingest.force_on_same_marc'';'
\qecho 'SELECT ''update config.internal_flag set enabled = true where name = ''''ingest.reingest.force_on_same_marc'''';'';'
\qecho 'SELECT ''update biblio.record_entry set id = id where id = '' || id || '';'' FROM biblio.record_entry WHERE NOT DELETED AND id > 0;'
\qecho 'SELECT ''-- Restore previous setting'';'
\qecho 'SELECT ''update config.internal_flag set enabled = :force_reingest where name = \'\'ingest.reingest.force_on_same_marc\'\';'';'
\qecho '\\o'
\qecho '\\t'

\t
\o reingest/biblio/record_entry.sql
SELECT '-- Grab current setting';
SELECT '\set force_reingest ' || enabled FROM config.internal_flag WHERE name = 'ingest.reingest.force_on_same_marc';
SELECT 'update config.internal_flag set enabled = true where name = ''ingest.reingest.force_on_same_marc'';';
SELECT 'update biblio.record_entry set id = id where id = ' || id || ';select pg_sleep(1);' FROM biblio.record_entry WHERE NOT DELETED AND id > 0;
SELECT '-- Restore previous setting';
SELECT 'update config.internal_flag set enabled = :force_reingest where name = ''ingest.reingest.force_on_same_marc'';';
\o
\t

\qecho '\\o reingest_2.5_auth_recs.sql'
\qecho 'SELECT ''-- Grab current setting'';'
\qecho 'SELECT ''\\set force_reingest '' || enabled FROM config.internal_flag WHERE name = ''ingest.reingest.force_on_same_marc'';'
\qecho 'SELECT ''update config.internal_flag set enabled = true where name = ''''ingest.reingest.force_on_same_marc'''';'';'
\qecho 'SELECT ''update authority.record_entry set id = id where id = '' || id || '';'' FROM authority.record_entry WHERE NOT DELETED;'
\qecho 'SELECT ''-- Restore previous setting'';'
\qecho 'SELECT ''update config.internal_flag set enabled = :force_reingest where name = \'\'ingest.reingest.force_on_same_marc\'\';'';'
\qecho '\\o'
\qecho '\\t'

\o reingest/authority/record_entry.sql
SELECT '-- Grab current setting';
SELECT '\set force_reingest ' || enabled FROM config.internal_flag WHERE name = 'ingest.reingest.force_on_same_marc';
SELECT 'update config.internal_flag set enabled = true where name = ''ingest.reingest.force_on_same_marc'';';
SELECT 'update authority.record_entry set id = id where id = ' || id || ';select pg_sleep(1);' FROM authority.record_entry WHERE NOT DELETED;
SELECT '-- Restore previous setting';
SELECT 'update config.internal_flag set enabled = :force_reingest where name = ''ingest.reingest.force_on_same_marc'';';
\o
\t

