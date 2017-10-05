--Upgrade Script for 2.4.3 to 2.5.0

\qecho **** REAL 2.5 upgrade starting now...

\set eg_version '''2.5.0'''
BEGIN;
INSERT INTO config.upgrade_log (version, applied_to) VALUES ('2.5.0', :eg_version);

SELECT evergreen.upgrade_deps_block_check('0794', :eg_version);

INSERT INTO config.standing_penalty (id,name,label,block_list,staff_alert)
    VALUES (5,'PATRON_EXCEEDS_LOST_COUNT',oils_i18n_gettext(5, 'Patron exceeds max lost item threshold', 'csp', 'label'),'CIRC|FULFILL|HOLD|CAPTURE|RENEW', TRUE);

INSERT INTO config.org_unit_setting_type ( name, grp, label, description, datatype ) VALUES (
    'circ.tally_lost', 'circ',
    oils_i18n_gettext(
        'circ.tally_lost',
        'Include Lost circulations in lump sum tallies in Patron Display.',
        'coust',
        'label'),
    oils_i18n_gettext(
        'circ.tally_lost',
        'In the Patron Display interface, the number of total active circulations for a given patron is presented in the Summary sidebar and underneath the Items Out navigation button.  This setting will include Lost circulations as counting toward these tallies.',
        'coust',
        'description'),
    'bool'
);

-- Function: actor.calculate_system_penalties(integer, integer)
-- DROP FUNCTION actor.calculate_system_penalties(integer, integer);

CREATE OR REPLACE FUNCTION actor.calculate_system_penalties(match_user integer, context_org integer)
    RETURNS SETOF actor.usr_standing_penalty AS
$BODY$
DECLARE
    user_object             actor.usr%ROWTYPE;
    new_sp_row            actor.usr_standing_penalty%ROWTYPE;
    existing_sp_row       actor.usr_standing_penalty%ROWTYPE;
    collections_fines      permission.grp_penalty_threshold%ROWTYPE;
    max_fines               permission.grp_penalty_threshold%ROWTYPE;
    max_overdue           permission.grp_penalty_threshold%ROWTYPE;
    max_items_out       permission.grp_penalty_threshold%ROWTYPE;
    max_lost      		     permission.grp_penalty_threshold%ROWTYPE;
    tmp_grp                 INT;
    items_overdue        INT;
    items_out              INT;
    items_lost	            INT;
    context_org_list     INT[];
    current_fines          NUMERIC(8,2) := 0.0;
    tmp_fines               NUMERIC(8,2);
    tmp_groc               RECORD;
    tmp_circ                RECORD;
    tmp_org                actor.org_unit%ROWTYPE;
    tmp_penalty          config.standing_penalty%ROWTYPE;
    tmp_depth            INTEGER;
BEGIN
    SELECT INTO user_object * FROM actor.usr WHERE id = match_user;

    -- Max fines
    SELECT INTO tmp_org * FROM actor.org_unit WHERE id = context_org;

    -- Fail if the user has a high fine balance
    LOOP
        tmp_grp := user_object.profile;
        LOOP
            SELECT * INTO max_fines FROM permission.grp_penalty_threshold WHERE grp = tmp_grp AND penalty = 1 AND org_unit = tmp_org.id;

            IF max_fines.threshold IS NULL THEN
                SELECT parent INTO tmp_grp FROM permission.grp_tree WHERE id = tmp_grp;
            ELSE
                EXIT;
            END IF;

            IF tmp_grp IS NULL THEN
                EXIT;
            END IF;
        END LOOP;

        IF max_fines.threshold IS NOT NULL OR tmp_org.parent_ou IS NULL THEN
            EXIT;
        END IF;

        SELECT * INTO tmp_org FROM actor.org_unit WHERE id = tmp_org.parent_ou;

    END LOOP;

    IF max_fines.threshold IS NOT NULL THEN

        RETURN QUERY
            SELECT  *
              FROM  actor.usr_standing_penalty
              WHERE usr = match_user
                    AND org_unit = max_fines.org_unit
                    AND (stop_date IS NULL or stop_date > NOW())
                    AND standing_penalty = 1;

        SELECT INTO context_org_list ARRAY_ACCUM(id) FROM actor.org_unit_full_path( max_fines.org_unit );

        SELECT  SUM(f.balance_owed) INTO current_fines
          FROM  money.materialized_billable_xact_summary f
                JOIN (
                    SELECT  r.id
                      FROM  booking.reservation r
                      WHERE r.usr = match_user
                            AND r.pickup_lib IN (SELECT * FROM unnest(context_org_list))
                            AND xact_finish IS NULL
                                UNION ALL
                    SELECT  g.id
                      FROM  money.grocery g
                      WHERE g.usr = match_user
                            AND g.billing_location IN (SELECT * FROM unnest(context_org_list))
                            AND xact_finish IS NULL
                                UNION ALL
                    SELECT  circ.id
                      FROM  action.circulation circ
                      WHERE circ.usr = match_user
                            AND circ.circ_lib IN (SELECT * FROM unnest(context_org_list))
                            AND xact_finish IS NULL ) l USING (id);

        IF current_fines >= max_fines.threshold THEN
            new_sp_row.usr := match_user;
            new_sp_row.org_unit := max_fines.org_unit;
            new_sp_row.standing_penalty := 1;
            RETURN NEXT new_sp_row;
        END IF;
    END IF;

    -- Start over for max overdue
    SELECT INTO tmp_org * FROM actor.org_unit WHERE id = context_org;

    -- Fail if the user has too many overdue items
    LOOP
        tmp_grp := user_object.profile;
        LOOP

            SELECT * INTO max_overdue FROM permission.grp_penalty_threshold WHERE grp = tmp_grp AND penalty = 2 AND org_unit = tmp_org.id;

            IF max_overdue.threshold IS NULL THEN
                SELECT parent INTO tmp_grp FROM permission.grp_tree WHERE id = tmp_grp;
            ELSE
                EXIT;
            END IF;

            IF tmp_grp IS NULL THEN
                EXIT;
            END IF;
        END LOOP;

        IF max_overdue.threshold IS NOT NULL OR tmp_org.parent_ou IS NULL THEN
            EXIT;
        END IF;

        SELECT INTO tmp_org * FROM actor.org_unit WHERE id = tmp_org.parent_ou;

    END LOOP;

    IF max_overdue.threshold IS NOT NULL THEN

        RETURN QUERY
            SELECT  *
              FROM  actor.usr_standing_penalty
              WHERE usr = match_user
                    AND org_unit = max_overdue.org_unit
                    AND (stop_date IS NULL or stop_date > NOW())
                    AND standing_penalty = 2;

        SELECT  INTO items_overdue COUNT(*)
          FROM  action.circulation circ
                JOIN  actor.org_unit_full_path( max_overdue.org_unit ) fp ON (circ.circ_lib = fp.id)
          WHERE circ.usr = match_user
            AND circ.checkin_time IS NULL
            AND circ.due_date < NOW()
            AND (circ.stop_fines = 'MAXFINES' OR circ.stop_fines IS NULL);

        IF items_overdue >= max_overdue.threshold::INT THEN
            new_sp_row.usr := match_user;
            new_sp_row.org_unit := max_overdue.org_unit;
            new_sp_row.standing_penalty := 2;
            RETURN NEXT new_sp_row;
        END IF;
    END IF;

    -- Start over for max out
    SELECT INTO tmp_org * FROM actor.org_unit WHERE id = context_org;

    -- Fail if the user has too many checked out items
    LOOP
        tmp_grp := user_object.profile;
        LOOP
            SELECT * INTO max_items_out FROM permission.grp_penalty_threshold WHERE grp = tmp_grp AND penalty = 3 AND org_unit = tmp_org.id;

            IF max_items_out.threshold IS NULL THEN
                SELECT parent INTO tmp_grp FROM permission.grp_tree WHERE id = tmp_grp;
            ELSE
                EXIT;
            END IF;

            IF tmp_grp IS NULL THEN
                EXIT;
            END IF;
        END LOOP;

        IF max_items_out.threshold IS NOT NULL OR tmp_org.parent_ou IS NULL THEN
            EXIT;
        END IF;

        SELECT INTO tmp_org * FROM actor.org_unit WHERE id = tmp_org.parent_ou;

    END LOOP;

    -- Fail if the user has too many items checked out
    IF max_items_out.threshold IS NOT NULL THEN
        RETURN QUERY
            SELECT  *
            FROM  actor.usr_standing_penalty
            WHERE usr = match_user
                AND org_unit = max_items_out.org_unit
                AND (stop_date IS NULL or stop_date > NOW())
                AND standing_penalty = 3;
            SELECT  INTO items_out COUNT(*)
            FROM  action.circulation circ
            JOIN  actor.org_unit_full_path( max_items_out.org_unit ) fp ON (circ.circ_lib = fp.id)
            WHERE circ.usr = match_user
                AND circ.checkin_time IS NULL
                AND (circ.stop_fines IN (
                    SELECT 'MAXFINES'::TEXT
                    UNION ALL
                    SELECT 'LONGOVERDUE'::TEXT
                    UNION ALL
                    SELECT 'LOST'::TEXT
                    WHERE 'true' ILIKE
                    (
                        SELECT CASE
                            WHEN (SELECT value FROM actor.org_unit_ancestor_setting('circ.tally_lost', circ.circ_lib)) ILIKE 'true' THEN 'true'
                            ELSE 'false'
                        END
                    )
                    UNION ALL
                    SELECT 'CLAIMSRETURNED'::TEXT
                    WHERE 'false' ILIKE
                        (
                            SELECT CASE
                            WHEN (SELECT value FROM actor.org_unit_ancestor_setting('circ.do_not_tally_claims_returned', circ.circ_lib)) ILIKE 'true' THEN 'true'
                            ELSE 'false'
                            END
                        )
                    ) OR circ.stop_fines IS NULL)
                AND xact_finish IS NULL;

    IF items_out >= max_items_out.threshold::INT THEN
        new_sp_row.usr := match_user;
        new_sp_row.org_unit := max_items_out.org_unit;
        new_sp_row.standing_penalty := 3;
        RETURN NEXT new_sp_row;
   END IF;
END IF;

    -- Start over for max lost
    SELECT INTO tmp_org * FROM actor.org_unit WHERE id = context_org;

    -- Fail if the user has too many lost items
    LOOP
        tmp_grp := user_object.profile;
        LOOP
            SELECT * INTO max_lost FROM permission.grp_penalty_threshold WHERE grp = tmp_grp AND penalty = 5 AND org_unit = tmp_org.id;
            IF max_lost.threshold IS NULL THEN
                SELECT parent INTO tmp_grp FROM permission.grp_tree WHERE id = tmp_grp;
            ELSE
                EXIT;
            END IF;

            IF tmp_grp IS NULL THEN
                EXIT;
            END IF;
        END LOOP;

        IF max_lost.threshold IS NOT NULL OR tmp_org.parent_ou IS NULL THEN
            EXIT;
        END IF;

        SELECT INTO tmp_org * FROM actor.org_unit WHERE id = tmp_org.parent_ou;

    END LOOP;

    IF max_lost.threshold IS NOT NULL THEN
        RETURN QUERY
            SELECT  *
            FROM  actor.usr_standing_penalty
            WHERE usr = match_user
                AND org_unit = max_lost.org_unit
                AND (stop_date IS NULL or stop_date > NOW())
                AND standing_penalty = 5;

        SELECT INTO items_lost COUNT(*)
        FROM  action.circulation circ
            JOIN  actor.org_unit_full_path( max_lost.org_unit ) fp ON (circ.circ_lib = fp.id)
            WHERE circ.usr = match_user
                AND circ.checkin_time IS NULL
                AND (circ.stop_fines = 'LOST')
                AND xact_finish IS NULL;

        IF items_lost >= max_lost.threshold::INT AND 0 < max_lost.threshold::INT THEN
            new_sp_row.usr := match_user;
            new_sp_row.org_unit := max_lost.org_unit;
            new_sp_row.standing_penalty := 5;
            RETURN NEXT new_sp_row;
        END IF;
    END IF;

    -- Start over for collections warning
    SELECT INTO tmp_org * FROM actor.org_unit WHERE id = context_org;

    -- Fail if the user has a collections-level fine balance
    LOOP
        tmp_grp := user_object.profile;
        LOOP
            SELECT * INTO max_fines FROM permission.grp_penalty_threshold WHERE grp = tmp_grp AND penalty = 4 AND org_unit = tmp_org.id;
            IF max_fines.threshold IS NULL THEN
                SELECT parent INTO tmp_grp FROM permission.grp_tree WHERE id = tmp_grp;
            ELSE
                EXIT;
            END IF;

            IF tmp_grp IS NULL THEN
                EXIT;
            END IF;
        END LOOP;

        IF max_fines.threshold IS NOT NULL OR tmp_org.parent_ou IS NULL THEN
            EXIT;
        END IF;

        SELECT * INTO tmp_org FROM actor.org_unit WHERE id = tmp_org.parent_ou;

    END LOOP;

    IF max_fines.threshold IS NOT NULL THEN

        RETURN QUERY
            SELECT  *
                FROM  actor.usr_standing_penalty
                WHERE usr = match_user
                    AND org_unit = max_fines.org_unit
                    AND (stop_date IS NULL or stop_date > NOW())
                    AND standing_penalty = 4;

        SELECT INTO context_org_list ARRAY_ACCUM(id) FROM actor.org_unit_full_path( max_fines.org_unit );

        SELECT  SUM(f.balance_owed) INTO current_fines
            FROM  money.materialized_billable_xact_summary f
                JOIN (
                    SELECT  r.id
                        FROM  booking.reservation r
                        WHERE r.usr = match_user
                            AND r.pickup_lib IN (SELECT * FROM unnest(context_org_list))
                            AND r.xact_finish IS NULL
                                UNION ALL
                    SELECT  g.id
                        FROM  money.grocery g
                        WHERE g.usr = match_user
                            AND g.billing_location IN (SELECT * FROM unnest(context_org_list))
                            AND g.xact_finish IS NULL
                                UNION ALL
                    SELECT  circ.id
                        FROM  action.circulation circ
                        WHERE circ.usr = match_user
                            AND circ.circ_lib IN (SELECT * FROM unnest(context_org_list))
                            AND circ.xact_finish IS NULL ) l USING (id);

        IF current_fines >= max_fines.threshold THEN
            new_sp_row.usr := match_user;
            new_sp_row.org_unit := max_fines.org_unit;
            new_sp_row.standing_penalty := 4;
            RETURN NEXT new_sp_row;
        END IF;
    END IF;

    -- Start over for in collections
    SELECT INTO tmp_org * FROM actor.org_unit WHERE id = context_org;

    -- Remove the in-collections penalty if the user has paid down enough
    -- This penalty is different, because this code is not responsible for creating 
    -- new in-collections penalties, only for removing them
    LOOP
        tmp_grp := user_object.profile;
        LOOP
            SELECT * INTO max_fines FROM permission.grp_penalty_threshold WHERE grp = tmp_grp AND penalty = 30 AND org_unit = tmp_org.id;

            IF max_fines.threshold IS NULL THEN
                SELECT parent INTO tmp_grp FROM permission.grp_tree WHERE id = tmp_grp;
            ELSE
                EXIT;
            END IF;

            IF tmp_grp IS NULL THEN
                EXIT;
            END IF;
        END LOOP;

        IF max_fines.threshold IS NOT NULL OR tmp_org.parent_ou IS NULL THEN
            EXIT;
        END IF;

        SELECT * INTO tmp_org FROM actor.org_unit WHERE id = tmp_org.parent_ou;

    END LOOP;

    IF max_fines.threshold IS NOT NULL THEN

        SELECT INTO context_org_list ARRAY_ACCUM(id) FROM actor.org_unit_full_path( max_fines.org_unit );

        -- first, see if the user had paid down to the threshold
        SELECT  SUM(f.balance_owed) INTO current_fines
          FROM  money.materialized_billable_xact_summary f
                JOIN (
                    SELECT  r.id
                        FROM  booking.reservation r
                        WHERE r.usr = match_user
                            AND r.pickup_lib IN (SELECT * FROM unnest(context_org_list))
                            AND r.xact_finish IS NULL
                                UNION ALL
                    SELECT  g.id
                        FROM  money.grocery g
                        WHERE g.usr = match_user
                            AND g.billing_location IN (SELECT * FROM unnest(context_org_list))
                            AND g.xact_finish IS NULL
                                UNION ALL
                    SELECT  circ.id
                        FROM  action.circulation circ
                        WHERE circ.usr = match_user
                            AND circ.circ_lib IN (SELECT * FROM unnest(context_org_list))
                            AND circ.xact_finish IS NULL ) l USING (id);

        IF current_fines IS NULL OR current_fines <= max_fines.threshold THEN
            -- patron has paid down enough

            SELECT INTO tmp_penalty * FROM config.standing_penalty WHERE id = 30;

            IF tmp_penalty.org_depth IS NOT NULL THEN

                -- since this code is not responsible for applying the penalty, it can't 
                -- guarantee the current context org will match the org at which the penalty 
                --- was applied.  search up the org tree until we hit the configured penalty depth
                SELECT INTO tmp_org * FROM actor.org_unit WHERE id = context_org;
                SELECT INTO tmp_depth depth FROM actor.org_unit_type WHERE id = tmp_org.ou_type;

                WHILE tmp_depth >= tmp_penalty.org_depth LOOP

                    RETURN QUERY
                        SELECT  *
                            FROM  actor.usr_standing_penalty
                            WHERE usr = match_user
                                AND org_unit = tmp_org.id
                                AND (stop_date IS NULL or stop_date > NOW())
                                AND standing_penalty = 30;

                    IF tmp_org.parent_ou IS NULL THEN
                        EXIT;
                    END IF;

                    SELECT * INTO tmp_org FROM actor.org_unit WHERE id = tmp_org.parent_ou;
                    SELECT INTO tmp_depth depth FROM actor.org_unit_type WHERE id = tmp_org.ou_type;
                END LOOP;

            ELSE

                -- no penalty depth is defined, look for exact matches

                RETURN QUERY
                    SELECT  *
                        FROM  actor.usr_standing_penalty
                        WHERE usr = match_user
                            AND org_unit = max_fines.org_unit
                            AND (stop_date IS NULL or stop_date > NOW())
                            AND standing_penalty = 30;
            END IF;

        END IF;

    END IF;

    RETURN;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
    COST 100
    ROWS 1000;


SELECT evergreen.upgrade_deps_block_check('0795', :eg_version);

CREATE OR REPLACE FUNCTION 
    evergreen.z3950_attr_name_is_valid(TEXT) RETURNS BOOLEAN AS $func$
    SELECT EXISTS (SELECT 1 FROM config.z3950_attr WHERE name = $1);
$func$ LANGUAGE SQL STRICT IMMUTABLE;

COMMENT ON FUNCTION evergreen.z3950_attr_name_is_valid(TEXT) IS $$
Results in TRUE if there exists at least one config.z3950_attr
with the provided name.  Used by config.z3950_index_field_map
to verify z3950_attr_type maps.
$$;

CREATE TABLE config.z3950_index_field_map (
    id              SERIAL  PRIMARY KEY,
    label           TEXT    NOT NULL, -- i18n
    metabib_field   INTEGER REFERENCES config.metabib_field(id) ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED,
    record_attr     TEXT    REFERENCES config.record_attr_definition(name),
    z3950_attr      INTEGER REFERENCES config.z3950_attr(id),
    z3950_attr_type TEXT,-- REFERENCES config.z3950_attr(name)
    CONSTRAINT metabib_field_or_record_attr CHECK (
        metabib_field IS NOT NULL OR 
        record_attr IS NOT NULL
    ),
    CONSTRAINT attr_or_attr_type CHECK (
        z3950_attr IS NOT NULL OR 
        z3950_attr_type IS NOT NULL
    ),
    -- ensure the selected z3950_attr_type refers to a valid attr name
    CONSTRAINT valid_z3950_attr_type CHECK (
        z3950_attr_type IS NULL OR 
            evergreen.z3950_attr_name_is_valid(z3950_attr_type)
    )
);

-- check whether patch can be applied
SELECT evergreen.upgrade_deps_block_check('0841', :eg_version);
SELECT evergreen.upgrade_deps_block_check('0842', :eg_version);
SELECT evergreen.upgrade_deps_block_check('0843', :eg_version);

ALTER TABLE config.metabib_field_ts_map DROP CONSTRAINT metabib_field_ts_map_metabib_field_fkey;
ALTER TABLE config.metabib_search_alias DROP CONSTRAINT metabib_search_alias_field_fkey;
ALTER TABLE metabib.browse_entry_def_map DROP CONSTRAINT browse_entry_def_map_def_fkey;

ALTER TABLE config.metabib_field_ts_map ADD CONSTRAINT metabib_field_ts_map_metabib_field_fkey FOREIGN KEY (metabib_field) REFERENCES config.metabib_field(id) ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE config.metabib_search_alias ADD CONSTRAINT metabib_search_alias_field_fkey FOREIGN KEY (field) REFERENCES config.metabib_field(id) ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;
ALTER TABLE metabib.browse_entry_def_map ADD CONSTRAINT browse_entry_def_map_def_fkey FOREIGN KEY (def) REFERENCES config.metabib_field(id) ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;



DROP FUNCTION IF EXISTS config.modify_metabib_field(source INT, target INT);
CREATE FUNCTION config.modify_metabib_field(v_source INT, target INT) RETURNS INT AS $func$
DECLARE
    f_class TEXT;
    check_id INT;
    target_id INT;
BEGIN
    SELECT field_class INTO f_class FROM config.metabib_field WHERE id = v_source;
    IF NOT FOUND THEN
        RETURN 0;
    END IF;
    IF target IS NULL THEN
        target_id = v_source + 1000;
    ELSE
        target_id = target;
    END IF;
    SELECT id FROM config.metabib_field INTO check_id WHERE id = target_id;
    IF FOUND THEN
        RAISE NOTICE 'Cannot bump config.metabib_field.id from % to %; the target ID already exists.', v_source, target_id;
        RETURN 0;
    END IF;
    UPDATE config.metabib_field SET id = target_id WHERE id = v_source;
    EXECUTE ' UPDATE metabib.' || f_class || '_field_entry SET field = ' || target_id || ' WHERE field = ' || v_source;
    UPDATE config.metabib_field_ts_map SET metabib_field = target_id WHERE metabib_field = v_source;
    UPDATE config.metabib_field_index_norm_map SET field = target_id WHERE field = v_source;
    UPDATE search.relevance_adjustment SET field = target_id WHERE field = v_source;
    UPDATE config.metabib_search_alias SET field = target_id WHERE field = v_source;
    UPDATE config.z3950_index_field_map SET metabib_field = target_id WHERE metabib_field = v_source;
    UPDATE metabib.browse_entry_def_map SET def = target_id WHERE def = v_source;
    RETURN 1;
END;
$func$ LANGUAGE PLPGSQL;

COMMIT;