BEGIN;

ALTER TABLE search.symspell_dictionary SET UNLOGGED;
TRUNCATE search.symspell_dictionary;

\i identifier.sql
\i author.sql
\i title.sql
\i subject.sql
\i series.sql
\i keyword.sql

CLUSTER search.symspell_dictionary USING symspell_dictionary_pkey;
REINDEX TABLE search.symspell_dictionary;
ALTER TABLE search.symspell_dictionary SET LOGGED;

COMMIT;

VACUUM ANALYZE search.symspell_dictionary;

DROP TABLE IF EXISTS search.symspell_dictionary_partial_title;
DROP TABLE IF EXISTS search.symspell_dictionary_partial_author;
DROP TABLE IF EXISTS search.symspell_dictionary_partial_subject;
DROP TABLE IF EXISTS search.symspell_dictionary_partial_series;
DROP TABLE IF EXISTS search.symspell_dictionary_partial_identifier;
DROP TABLE IF EXISTS search.symspell_dictionary_partial_keyword;
