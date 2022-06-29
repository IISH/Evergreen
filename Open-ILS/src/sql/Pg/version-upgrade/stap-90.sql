BEGIN

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
VACUUM ANALYZE search.symspell_dictionary;

COMMIT

DROP TABLE search.symspell_dictionary_partial_title;
DROP TABLE search.symspell_dictionary_partial_author;
DROP TABLE search.symspell_dictionary_partial_subject;
DROP TABLE search.symspell_dictionary_partial_series;
DROP TABLE search.symspell_dictionary_partial_identifier;
DROP TABLE search.symspell_dictionary_partial_keyword;
