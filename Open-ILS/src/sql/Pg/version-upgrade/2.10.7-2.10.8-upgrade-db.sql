--Upgrade Script for 2.10.7 to 2.10.8
\set eg_version '''2.10.8'''
BEGIN;
INSERT INTO config.upgrade_log (version, applied_to) VALUES ('2.10.8', :eg_version);

SELECT evergreen.upgrade_deps_block_check('1001', :eg_version); -- stompro/gmcharlt

CREATE INDEX action_usr_circ_history_usr_idx ON action.usr_circ_history ( usr );

-- Add Spanish to config.i18n_locale table
SELECT evergreen.upgrade_deps_block_check('1002', :eg_version);

INSERT INTO config.i18n_locale (code,marc_code,name,description)
    SELECT 'es-ES', 'spa', oils_i18n_gettext('es-ES', 'Spanish', 'i18n_l', 'name'),
        oils_i18n_gettext('es-ES', 'Spanish', 'i18n_l', 'description')
    WHERE NOT EXISTS (SELECT 1 FROM config.i18n_locale WHERE code = 'es-ES');

SELECT evergreen.upgrade_deps_block_check('1003', :eg_version); -- gmcharlt/rhamby/csharp

CREATE OR REPLACE FUNCTION metabib.remap_metarecord_for_bib( bib_id BIGINT, fp TEXT, bib_is_deleted BOOL DEFAULT FALSE, retain_deleted BOOL DEFAULT FALSE ) RETURNS BIGINT AS $func$
DECLARE
    new_mapping     BOOL := TRUE;
    source_count    INT;
    old_mr          BIGINT;
    tmp_mr          metabib.metarecord%ROWTYPE;
    deleted_mrs     BIGINT[];
BEGIN

    -- We need to make sure we're not a deleted master record of an MR
    IF bib_is_deleted THEN
        FOR old_mr IN SELECT id FROM metabib.metarecord WHERE master_record = bib_id LOOP

            IF NOT retain_deleted THEN -- Go away for any MR that we're master of, unless retained
                DELETE FROM metabib.metarecord_source_map WHERE source = bib_id;
            END IF;

            -- Now, are there any more sources on this MR?
            SELECT COUNT(*) INTO source_count FROM metabib.metarecord_source_map WHERE metarecord = old_mr;

            IF source_count = 0 AND NOT retain_deleted THEN -- No other records
                deleted_mrs := ARRAY_APPEND(deleted_mrs, old_mr); -- Just in case...
                DELETE FROM metabib.metarecord WHERE id = old_mr;

            ELSE -- indeed there are. Update it with a null cache and recalcualated master record
                UPDATE  metabib.metarecord
                  SET   mods = NULL,
                        master_record = ( SELECT id FROM biblio.record_entry WHERE fingerprint = fp AND NOT deleted ORDER BY quality DESC LIMIT 1)
                  WHERE id = old_mr;
            END IF;
        END LOOP;

    ELSE -- insert or update

        FOR tmp_mr IN SELECT m.* FROM metabib.metarecord m JOIN metabib.metarecord_source_map s ON (s.metarecord = m.id) WHERE s.source = bib_id LOOP

            -- Find the first fingerprint-matching
            IF old_mr IS NULL AND fp = tmp_mr.fingerprint THEN
                old_mr := tmp_mr.id;
                new_mapping := FALSE;

            ELSE -- Our fingerprint changed ... maybe remove the old MR
                DELETE FROM metabib.metarecord_source_map WHERE metarecord = tmp_mr.id AND source = bib_id; -- remove the old source mapping
                SELECT COUNT(*) INTO source_count FROM metabib.metarecord_source_map WHERE metarecord = tmp_mr.id;
                IF source_count = 0 THEN -- No other records
                    deleted_mrs := ARRAY_APPEND(deleted_mrs, tmp_mr.id);
                    DELETE FROM metabib.metarecord WHERE id = tmp_mr.id;
                END IF;
            END IF;

        END LOOP;

        -- we found no suitable, preexisting MR based on old source maps
        IF old_mr IS NULL THEN
            SELECT id INTO old_mr FROM metabib.metarecord WHERE fingerprint = fp; -- is there one for our current fingerprint?

            IF old_mr IS NULL THEN -- nope, create one and grab its id
                INSERT INTO metabib.metarecord ( fingerprint, master_record ) VALUES ( fp, bib_id );
                SELECT id INTO old_mr FROM metabib.metarecord WHERE fingerprint = fp;

            ELSE -- indeed there is. update it with a null cache and recalcualated master record
                UPDATE  metabib.metarecord
                  SET   mods = NULL,
                        master_record = ( SELECT id FROM biblio.record_entry WHERE fingerprint = fp AND NOT deleted ORDER BY quality DESC LIMIT 1)
                  WHERE id = old_mr;
            END IF;

        ELSE -- there was one we already attached to, update its mods cache and master_record
            UPDATE  metabib.metarecord
              SET   mods = NULL,
                    master_record = ( SELECT id FROM biblio.record_entry WHERE fingerprint = fp AND NOT deleted ORDER BY quality DESC LIMIT 1)
              WHERE id = old_mr;
        END IF;

        IF new_mapping THEN
            INSERT INTO metabib.metarecord_source_map (metarecord, source) VALUES (old_mr, bib_id); -- new source mapping
        END IF;

    END IF;

    IF ARRAY_UPPER(deleted_mrs,1) > 0 THEN
        UPDATE action.hold_request SET target = old_mr WHERE target IN ( SELECT unnest(deleted_mrs) ) AND hold_type = 'M'; -- if we had to delete any MRs above, make sure their holds are moved
    END IF;

    RETURN old_mr;

END;
$func$ LANGUAGE PLPGSQL;

COMMIT;
