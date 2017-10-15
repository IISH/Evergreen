-- Open-ILS/src/sql/Pg/version-upgrade/2.7.2-2.7.3-upgrade-db.sql
SELECT 'select metabib.reingest_record_attributes(' || id || ');'
    FROM biblio.record_entry
    WHERE NOT DELETED AND id > 0;

-- Open-ILS/src/sql/Pg/version-upgrade/2.9.3-2.10.0-upgrade-db.sql
SELECT metabib.reingest_metabib_field_entries(record, FALSE, TRUE, FALSE)
    FROM metabib.real_full_rec
    WHERE tag IN ('655')
    GROUP BY record;

SELECT COUNT(metabib.reingest_record_attributes(id))
    FROM biblio.record_entry
    WHERE deleted IS FALSE;


-- Open-ILS/src/sql/Pg/version-upgrade/2.10.7-2.11.0-upgrade-db.sql
UPDATE biblio.record_entry
    SET id = id
    WHERE source IS NOT NULL;

-- Open-ILS/src/sql/Pg/version-upgrade/2.11.3-2.12.0-upgrade-db.sql
--SELECT metabib.reingest_metabib_field_entries(id, FALSE, FALSE, TRUE)
--    FROM biblio.record_entry;

-- Open-ILS/src/sql/Pg/version-upgrade/2.12.0-2.12.1-upgrade-db.sql
SELECT metabib.reingest_metabib_field_entries(id, TRUE, FALSE, TRUE)
    FROM biblio.record_entry;