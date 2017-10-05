--Upgrade Script for 2.1 to 2.2.0

-- 2.2.0   | 2013-01-10 01:30:53.978171+01
-- 0526    | 2013-01-10 01:30:53.978171+01
-- 0536    | 2013-01-10 01:30:53.978171+01
-- 0537    | 2013-01-10 01:30:53.978171+01
-- 0544    | 2013-01-10 01:30:53.978171+01

-- Don't require use of -vegversion=something
\set eg_version '''2.2.0'''

-- DROP objects that might have existed from a prior run of 0526
-- Yes this is ironic.
DROP TABLE IF EXISTS config.db_patch_dependencies;
ALTER TABLE config.upgrade_log DROP COLUMN IF EXISTS applied_to;
DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_deprecates(TEXT);
DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_supersedes(TEXT);
         --skipped
BEGIN;
--skip INSERT INTO config.upgrade_log (version) VALUES ('2.2.0');

--skip INSERT INTO config.upgrade_log (version) VALUES ('0526'); --miker

CREATE TABLE config.db_patch_dependencies (
  db_patch      TEXT PRIMARY KEY,
  supersedes    TEXT[],
  deprecates    TEXT[]
);

CREATE OR REPLACE FUNCTION evergreen.array_overlap_check (/* field */) RETURNS TRIGGER AS $$
DECLARE
    fld     TEXT;
    cnt     INT;
BEGIN
    fld := TG_ARGV[1];
    EXECUTE 'SELECT COUNT(*) FROM '|| TG_TABLE_SCHEMA ||'.'|| TG_TABLE_NAME ||' WHERE '|| fld ||' && ($1).'|| fld INTO cnt USING NEW;
    IF cnt > 0 THEN
        RAISE EXCEPTION 'Cannot insert duplicate array into field % of table %', fld, TG_TABLE_SCHEMA ||'.'|| TG_TABLE_NAME;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE PLPGSQL;

CREATE TRIGGER no_overlapping_sups
    BEFORE INSERT OR UPDATE ON config.db_patch_dependencies
    FOR EACH ROW EXECUTE PROCEDURE evergreen.array_overlap_check ('supersedes');

CREATE TRIGGER no_overlapping_deps
    BEFORE INSERT OR UPDATE ON config.db_patch_dependencies
    FOR EACH ROW EXECUTE PROCEDURE evergreen.array_overlap_check ('deprecates');

ALTER TABLE config.upgrade_log
    ADD COLUMN applied_to TEXT;

-- Provide a named type for patching functions
-- skip CREATE TYPE evergreen.patch AS (patch TEXT);

-- List applied db patches that are deprecated by (and block the application of) my_db_patch
CREATE OR REPLACE FUNCTION evergreen.upgrade_list_applied_deprecates ( my_db_patch TEXT ) RETURNS SETOF evergreen.patch AS $$
    SELECT  DISTINCT l.version
      FROM  config.upgrade_log l
            JOIN config.db_patch_dependencies d ON (l.version::TEXT[] && d.deprecates)
      WHERE d.db_patch = $1
$$ LANGUAGE SQL;

-- List applied db patches that are superseded by (and block the application of) my_db_patch
CREATE OR REPLACE FUNCTION evergreen.upgrade_list_applied_supersedes ( my_db_patch TEXT ) RETURNS SETOF evergreen.patch AS $$
    SELECT  DISTINCT l.version
      FROM  config.upgrade_log l
            JOIN config.db_patch_dependencies d ON (l.version::TEXT[] && d.supersedes)
      WHERE d.db_patch = $1
$$ LANGUAGE SQL;

DROP FUNCTION IF EXISTS evergreen.upgrade_deps_block_check(text,text);
DROP FUNCTION IF EXISTS evergreen.upgrade_verify_no_dep_conflicts(text);
DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_deprecated(text);
DROP FUNCTION IF EXISTS evergreen.upgrade_list_applied_superseded(text);

-- List applied db patches that deprecates (and block the application of) my_db_patch
CREATE OR REPLACE FUNCTION evergreen.upgrade_list_applied_deprecated ( my_db_patch TEXT ) RETURNS TEXT AS $$
    SELECT  db_patch
      FROM  config.db_patch_dependencies
      WHERE ARRAY[$1]::TEXT[] && deprecates
$$ LANGUAGE SQL;

-- List applied db patches that supersedes (and block the application of) my_db_patch
CREATE OR REPLACE FUNCTION evergreen.upgrade_list_applied_superseded ( my_db_patch TEXT ) RETURNS TEXT AS $$
    SELECT  db_patch
      FROM  config.db_patch_dependencies
      WHERE ARRAY[$1]::TEXT[] && supersedes
$$ LANGUAGE SQL;

-- Make sure that no deprecated or superseded db patches are currently applied
CREATE OR REPLACE FUNCTION evergreen.upgrade_verify_no_dep_conflicts ( my_db_patch TEXT ) RETURNS BOOL AS $$
    SELECT  COUNT(*) = 0
      FROM  (SELECT * FROM evergreen.upgrade_list_applied_deprecates( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_supersedes( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_deprecated( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_superseded( $1 ))x
$$ LANGUAGE SQL;

-- Raise an exception if there are, in fact, dep/sup confilct
CREATE OR REPLACE FUNCTION evergreen.upgrade_deps_block_check ( my_db_patch TEXT, my_applied_to TEXT ) RETURNS BOOL AS $$
DECLARE 
    deprecates TEXT;
    supersedes TEXT;
BEGIN
    IF NOT evergreen.upgrade_verify_no_dep_conflicts( my_db_patch ) THEN
        SELECT  STRING_AGG(patch, ', ') INTO deprecates FROM evergreen.upgrade_list_applied_deprecates(my_db_patch);
        SELECT  STRING_AGG(patch, ', ') INTO supersedes FROM evergreen.upgrade_list_applied_supersedes(my_db_patch);
        RAISE EXCEPTION '
Upgrade script % can not be applied:
  applied deprecated scripts %
  applied superseded scripts %
  deprecated by %
  superseded by %',
            my_db_patch,
            ARRAY_AGG(evergreen.upgrade_list_applied_deprecates(my_db_patch)),
            ARRAY_AGG(evergreen.upgrade_list_applied_supersedes(my_db_patch)),
            evergreen.upgrade_list_applied_deprecated(my_db_patch),
            evergreen.upgrade_list_applied_superseded(my_db_patch);
    END IF;

    INSERT INTO config.upgrade_log (version, applied_to) VALUES (my_db_patch, my_applied_to);
    RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;

-- Evergreen DB patch 0536.schema.lazy_circ-barcode_lookup.sql
--
-- FIXME: insert description of change, if needed
--

-- check whether patch can be applied
-- skip INSERT INTO config.upgrade_log (version) VALUES ('0536');

-- skip INSERT INTO config.org_unit_setting_type ( name, label, description, datatype) VALUES ( 'circ.staff_client.actor_on_checkout', 'Load patron from Checkout', 'When scanning barcodes into Checkout auto-detect if a new patron barcode is scanned and auto-load the new patron.', 'bool');

-- skip CREATE TABLE config.barcode_completion (
-- skip    id          SERIAL  PRIMARY KEY,
-- skip    active      BOOL    NOT NULL DEFAULT true,
-- skip    org_unit    INT     NOT NULL REFERENCES actor.org_unit (id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
-- skip    prefix      TEXT,
-- skip    suffix      TEXT,
-- skip    length      INT     NOT NULL DEFAULT 0,
-- skip    padding     TEXT,
-- skip    padding_end BOOL    NOT NULL DEFAULT false,
-- skip    asset       BOOL    NOT NULL DEFAULT true,
-- skip    actor       BOOL    NOT NULL DEFAULT true
-- skip);

-- skip CREATE TYPE evergreen.barcode_set AS (type TEXT, id BIGINT, barcode TEXT);

CREATE OR REPLACE FUNCTION evergreen.get_barcodes(select_ou INT, type TEXT, in_barcode TEXT) RETURNS SETOF evergreen.barcode_set AS $$
DECLARE
    cur_barcode TEXT;
    barcode_len INT;
    completion_len  INT;
    asset_barcodes  TEXT[];
    actor_barcodes  TEXT[];
    do_asset    BOOL = false;
    do_serial   BOOL = false;
    do_booking  BOOL = false;
    do_actor    BOOL = false;
    completion_set  config.barcode_completion%ROWTYPE;
BEGIN

    IF position('asset' in type) > 0 THEN
        do_asset = true;
    END IF;
    IF position('serial' in type) > 0 THEN
        do_serial = true;
    END IF;
    IF position('booking' in type) > 0 THEN
        do_booking = true;
    END IF;
    IF do_asset OR do_serial OR do_booking THEN
        asset_barcodes = asset_barcodes || in_barcode;
    END IF;
    IF position('actor' in type) > 0 THEN
        do_actor = true;
        actor_barcodes = actor_barcodes || in_barcode;
    END IF;

    barcode_len := length(in_barcode);

    FOR completion_set IN
      SELECT * FROM config.barcode_completion
        WHERE active
        AND org_unit IN (SELECT aou.id FROM actor.org_unit_ancestors(select_ou) aou)
        LOOP
        IF completion_set.prefix IS NULL THEN
            completion_set.prefix := '';
        END IF;
        IF completion_set.suffix IS NULL THEN
            completion_set.suffix := '';
        END IF;
        IF completion_set.length = 0 OR completion_set.padding IS NULL OR length(completion_set.padding) = 0 THEN
            cur_barcode = completion_set.prefix || in_barcode || completion_set.suffix;
        ELSE
            completion_len = completion_set.length - length(completion_set.prefix) - length(completion_set.suffix);
            IF completion_len >= barcode_len THEN
                IF completion_set.padding_end THEN
                    cur_barcode = rpad(in_barcode, completion_len, completion_set.padding);
                ELSE
                    cur_barcode = lpad(in_barcode, completion_len, completion_set.padding);
                END IF;
                cur_barcode = completion_set.prefix || cur_barcode || completion_set.suffix;
            END IF;
        END IF;
        IF completion_set.actor THEN
            actor_barcodes = actor_barcodes || cur_barcode;
        END IF;
        IF completion_set.asset THEN
            asset_barcodes = asset_barcodes || cur_barcode;
        END IF;
    END LOOP;

    IF do_asset AND do_serial THEN
        RETURN QUERY SELECT 'asset'::TEXT, id, barcode FROM ONLY asset.copy WHERE barcode = ANY(asset_barcodes) AND deleted = false;
        RETURN QUERY SELECT 'serial'::TEXT, id, barcode FROM serial.unit WHERE barcode = ANY(asset_barcodes) AND deleted = false;
    ELSIF do_asset THEN
        RETURN QUERY SELECT 'asset'::TEXT, id, barcode FROM asset.copy WHERE barcode = ANY(asset_barcodes) AND deleted = false;
    ELSIF do_serial THEN
        RETURN QUERY SELECT 'serial'::TEXT, id, barcode FROM serial.unit WHERE barcode = ANY(asset_barcodes) AND deleted = false;
    END IF;
    IF do_booking THEN
        RETURN QUERY SELECT 'booking'::TEXT, id::BIGINT, barcode FROM booking.resource WHERE barcode = ANY(asset_barcodes);
    END IF;
    IF do_actor THEN
        RETURN QUERY SELECT 'actor'::TEXT, c.usr::BIGINT, c.barcode FROM actor.card c JOIN actor.usr u ON c.usr = u.id WHERE c.barcode = ANY(actor_barcodes) AND c.active AND NOT u.deleted ORDER BY usr;
    END IF;
    RETURN;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION evergreen.get_barcodes(INT, TEXT, TEXT) IS $$
Given user input, find an appropriate barcode in the proper class.

Will add prefix/suffix information to do so, and return all results.
$$;



-- skip INSERT INTO config.upgrade_log (version) VALUES ('0537'); --miker

DROP FUNCTION evergreen.upgrade_deps_block_check(text,text);
DROP FUNCTION evergreen.upgrade_verify_no_dep_conflicts(text);
DROP FUNCTION evergreen.upgrade_list_applied_deprecated(text);
DROP FUNCTION evergreen.upgrade_list_applied_superseded(text);

-- List applied db patches that deprecates (and block the application of) my_db_patch
CREATE FUNCTION evergreen.upgrade_list_applied_deprecated ( my_db_patch TEXT ) RETURNS SETOF TEXT AS $$
    SELECT  db_patch
      FROM  config.db_patch_dependencies
      WHERE ARRAY[$1]::TEXT[] && deprecates
$$ LANGUAGE SQL;

-- List applied db patches that supersedes (and block the application of) my_db_patch
CREATE FUNCTION evergreen.upgrade_list_applied_superseded ( my_db_patch TEXT ) RETURNS SETOF TEXT AS $$
    SELECT  db_patch
      FROM  config.db_patch_dependencies
      WHERE ARRAY[$1]::TEXT[] && supersedes
$$ LANGUAGE SQL;

-- Make sure that no deprecated or superseded db patches are currently applied
CREATE FUNCTION evergreen.upgrade_verify_no_dep_conflicts ( my_db_patch TEXT ) RETURNS BOOL AS $$
    SELECT  COUNT(*) = 0
      FROM  (SELECT * FROM evergreen.upgrade_list_applied_deprecates( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_supersedes( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_deprecated( $1 )
                UNION
             SELECT * FROM evergreen.upgrade_list_applied_superseded( $1 ))x
$$ LANGUAGE SQL;

-- Raise an exception if there are, in fact, dep/sup confilct
CREATE FUNCTION evergreen.upgrade_deps_block_check ( my_db_patch TEXT, my_applied_to TEXT ) RETURNS BOOL AS $$
BEGIN
    IF NOT evergreen.upgrade_verify_no_dep_conflicts( my_db_patch ) THEN
        RAISE EXCEPTION '
Upgrade script % can not be applied:
  applied deprecated scripts %
  applied superseded scripts %
  deprecated by %
  superseded by %',
            my_db_patch,
            ARRAY_ACCUM(evergreen.upgrade_list_applied_deprecates(my_db_patch)),
            ARRAY_ACCUM(evergreen.upgrade_list_applied_supersedes(my_db_patch)),
            evergreen.upgrade_list_applied_deprecated(my_db_patch),
            evergreen.upgrade_list_applied_superseded(my_db_patch);
    END IF;

    INSERT INTO config.upgrade_log (version, applied_to) VALUES (my_db_patch, my_applied_to);
    RETURN TRUE;
END;
$$ LANGUAGE PLPGSQL;


-- skip INSERT INTO config.upgrade_log (version) VALUES ('0544');

-- skip INSERT INTO config.usr_setting_type
-- skip ( name, opac_visible, label, description, datatype) VALUES
-- skip ( 'circ.collections.exempt',
-- skip   FALSE,
-- skip   oils_i18n_gettext('circ.collections.exempt', 'Collections: Exempt', 'cust', 'description'),
-- skip   oils_i18n_gettext('circ.collections.exempt', 'User is exempt from collections tracking/processing', 'cust', 'description'),
-- skip   'bool'
-- skip );



-- skip SELECT evergreen.upgrade_deps_block_check('0545', :eg_version);

-- skip INSERT INTO permission.perm_list VALUES
-- skip  (507, 'ABORT_TRANSIT_ON_LOST', oils_i18n_gettext(507, 'Allows a user to abort a transit on a copy with status of LOST', 'ppl', 'description')),
-- skip  (508, 'ABORT_TRANSIT_ON_MISSING', oils_i18n_gettext(508, 'Allows a user to abort a transit on a copy with status of MISSING', 'ppl', 'description'));

--- stock Circulation Administrator group

INSERT INTO permission.grp_perm_map ( grp, perm, depth, grantable )
    SELECT
        4,
        id,
        0,
        't'
    FROM permission.perm_list
    WHERE code in ('ABORT_TRANSIT_ON_LOST', 'ABORT_TRANSIT_ON_MISSING');

-- Evergreen DB patch 0546.schema.sip_statcats.sql


COMMIT ;