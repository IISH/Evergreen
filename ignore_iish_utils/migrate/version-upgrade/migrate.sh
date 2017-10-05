#!/bin/bash
#
# Migrate Evergreen 2.2-RC1 to 2.7.1
#
# To be run from the same folder as this file: migrate.sh

a=$1
if [ -z "$a" ] ; then
    echo "Start this program with a password: ./migrate.sh [password]"
fi

a="evergreen"
PGHOST="evergreen-db0-acc.iisg.net"
PGPORT=5432
PGDATABASE="$a"
PGUSER="$a"
PGPASSWORD="$a"
export PGHOST PGPORT PGDATABASE PGUSER PGPASSWORD

# 1 ====================================================
# Restore the dump on the database server
sudo -u evergreen psql evergreen -f /data/evergreen.2014-12-xx.dump


# 2 ====================================================
# Add index
# Two create index commands may fail, because the namespace cannot be found.
# Set the search_path and manually add them.
#
psql -c "SET search_path = authority, pg_catalog, public; \
    CREATE INDEX by_heading ON record_entry USING btree (simple_normalize_heading(marc)) WHERE ((deleted IS FALSE) OR (deleted = false)); \
    CREATE INDEX by_heading_and_thesaurus ON record_entry USING btree (normalize_heading(marc)) WHERE ((deleted IS FALSE) OR (deleted = false));"


# 3 ====================================================
# Set search_path
psql -c "ALTER ROLE evergreen SET search_path TO evergreen, public, pg_catalog;"



# 5.1 Insert missing record
# Originally set in 1.6.1-2.0-upgrade-db.sql
psql -c "INSERT INTO container.biblio_record_entry_bucket_type (code,label) VALUES ('template_merge','Template Merge Container');"


# 4 ====================================================
# Enter the /Open-ILS/src/sql/Pg folder and run the upgrade scripts.
# All files with a .fix.sql extension are altered to prevent errors.


# 4.1 ====================================================
# # 2.1-2.2-a-upgrade-db.fix.sql
# All 2.2.x ( and beyond ) scripts expect a config.upgrade_log to have a field called 'applied_to':. But it does not.
# This script will repeat an upgrade step from 2.1 to 2.2 where the table and dependent stored procedures are added.
psql -f 2.1-2.2-a-upgrade-db.fix.sql
psql -c "-- "

# 4.2 ====================================================
# 2.1-2.2-b-upgrade-db.fix.sql
# This script may fail. It will rerun all remaining updates from 2.1 to 2.2 to ensure they were performed.
psql -c "-- ======================== failures from here are allowed"
psql -c "-- "
psql -f 2.1-2.2-b-upgrade-db.fix.sql


# 4.3.1 ====================================================
# Smaller updates that are also called in  2.2-2.3.0-upgrade-db.fix.sql
# May not be relevant at all, but nonetheless some break because they try to add, update or remove something that is already done..
# We removed the problematic statements:

psql -c "-- ======================== failures from here are NOT allowed"
psql -f 2.2.0-2.2.1-upgrade-db.fix.sql
# skipped: ALTER TABLE acq.purchase_order ADD CONSTRAINT valid_po_state CHECK (state IN ('new','pending','on-order','received','cancelled'));

psql -f 2.2.1-2.2.2-upgrade-db.fix.sql
# skipped: INSERT INTO permission.perm_list (id, code, description)
#    VALUES (539, 'UPDATE_ORG_UNIT_SETTING.ui.hide_copy_editor_fields', 'Allows staff to edit displayed copy editor fields');

psql -f 2.2.2-2.2.3-upgrade-db.fix.sql
# skipped DROP FUNCTION vandelay.get_expr_from_match_set( INTEGER );
# DROP FUNCTION vandelay.get_expr_from_match_set_point( vandelay.match_set_point );
# DROP FUNCTION vandelay._get_expr_push_jrow( vandelay.match_set_point );

psql -f 2.2.3-2.2.4-upgrade-db.sql
psql -f 2.2.4-2.2.5-upgrade-db.sql


# 4.3.2 ====================================================
# 2.2-2.3.0-upgrade-db.fix.sql
# This script have the following marked out, because those columns already exists:
# ALTER TABLE vandelay.import_item_attr_definition ADD COLUMN internal_id TEXT;
# ALTER TABLE vandelay.import_item ADD COLUMN internal_id BIGINT;
psql -f 2.2-2.3.0-upgrade-db.fix.sql


# 4.4 ====================================================
psql -f 2.3-2.4.0-upgrade-db.sql
psql -f 2.4.0-2.4.1-upgrade-db.sql
./2.3-2.4-supplemental.sh
psql -f 2.4.1-2.4.2-upgrade-db.sql
psql -f 2.4.2-2.4.3-upgrade-db.sql


# 4.5.1 ====================================================
# 2.4.3-2.5.0-a-upgrade-db.fix.sql
# 2.4.3-2.5.0-b-upgrade-db.fix.sql
# No changes. This is to prepare for 2.4.3-2.5.0-c-upgrade-db.fix.sql
# The first may fail. The second will take a long time, so we separate it
# psql -f 2.4.3-2.5.0-a-upgrade-db.fix.sql
psql -f 2.4.3-2.5.0-b-upgrade-db.fix.sql


# 4.5.2 ====================================================
# 2.4.3-2.5.0-b-upgrade-db.fix.sql
# -- values that Evergreen and it's upgrade procedures expect are:
# -- 950.data.seed-values.sql
# --    (28, 'identifier', 'authority_id', oils_i18n_gettext(28, 'Authority Record ID', 'cmf', 'label'), 'marcxml', '//marc:datafield/marc:subfield[@code="0"]', FALSE, TRUE, FALSE);
# --    (29, 'identifier', 'scn', oils_i18n_gettext(29, 'System Control Number', 'cmf', 'label'), 'marcxml', $$//marc:datafield[@tag='035']/marc:subfield[@code="a"]$$, FALSE);
# --    (30, 'identifier', 'lccn', oils_i18n_gettext(30, 'LC Control Number', 'cmf', 'label'), 'marcxml', $$//marc:datafield[@tag='010']/marc:subfield[@code="a" or @code='z']$$, FALSE);
# --    (31, 'title', 'browse', oils_i18n_gettext(31, 'Title Proper (Browse)', 'cmf', 'label'), 'mods32', $$//mods32:mods/mods32:titleBrowse$$, FALSE, '//@xlink:href', TRUE, $$*[local-name() != "nonSort"]$$ );
# --    (32, 'series', 'browse', oils_i18n_gettext(32, 'Series Title (Browse)', 'cmf', 'label'), 'mods32', $$//mods32:mods/mods32:relatedItem[@type="series"]/mods32:titleInfo[@type="nfi"]$$, FALSE, '//@xlink:href', TRUE, $$*[local-name() != "nonSort"]$$ );
#
#-- but in the database we find:
# -- 28 | author      | MARC author     | Authors                     | //marc:datafield[@tag="710"]                                                                       |      2 | marcxml | t            | f           |                              | t            |              | f
# -- 29 | author      | MARC author 711 | Authors 711                 | //marc:datafield[@tag="711"]                                                                       |      2 | marcxml | t            | f           |                              | t            |              | f
# -- 58 | identifier  | authority_id    | Authority Record ID         | //marc:datafield/marc:subfield[@code="0"]                                                          |      1 | marcxml | f            | t           |                              | f            |              | f
# -- 59 | identifier  | scn             | System Control Number       | //marc:datafield[@tag='035']/marc:subfield[@code="a"]                                              |      1 | marcxml | t            | f           |                              | f            |              | f
# -- 60 | identifier  | lccn            | LC Control Number           | //marc:datafield[@tag='010']/marc:subfield[@code="a" or @code='z']                                 |      1 | marcxml | t            | f           |
#
# This fails. Therefore we reorder the identifiers to the expected values:
# SELECT config.modify_metabib_field(28, 1028)
# SELECT config.modify_metabib_field(29, 1029)
# SELECT config.modify_metabib_field(58, 28)
# SELECT config.modify_metabib_field(59, 29)
# SELECT config.modify_metabib_field(60, 30)
#
# So now we can perform the statement without error:
# SELECT config.modify_metabib_field(id, NULL)
#    FROM config.metabib_field
#    WHERE id > 60 and id < 1000;
psql -f 2.4.3-2.5.0-c-upgrade-db.fix.sql


psql -f 2.5.0-2.5.1-upgrade-db.sql
psql -f 2.5.1-2.5.2-upgrade-db.sql
psql -f 2.5.2-2.5.3-upgrade-db.sql
psql -f 2.5.3-2.6.0-upgrade-db.sql
psql -f 2.6.0-2.6.1-upgrade-db.sql
psql -f 2.6.1-2.6.2-upgrade-db.sql
psql -f 2.6-2.7.0-upgrade-db.sql
psql -f 2.7.0-2.7.1-upgrade-db.sql


# ====================================================
# 5. Inconsistencies: Evergreen IISH differs from out-of-the-box (box) installation
#



# 5.2 action.Circulation
# Box has no column: id bigint DEFAULT nextval('money.billable_xact_id_seq'::regclass),
# Action: ignore

# 5.3 CREATE FUNCTION org_unit_descendants_distance(integer) RETURNS TABLE(id integer, distance integer)
# Small difference: IISH uses ou.parent_ou = oudd.id and BOX uses (ou.parent_ou = oudd.id)
# Action: rerun 020.schema.functions.sql

# 5.4 CREATE FUNCTION org_unit_full_path(integer) and actor.org_unit_full_path
# Originally set in 2.0-2.1-upgrade-db.sql

# 5.5 IISH uses: LANGUAGE sql STABLE ROWS 2
# Box uses: LANGUAGE sql STABLE ROWS 1
# Action: rerun 020.schema.functions.sql

# 5.6 Dynamic function creation: FUNCTION auditor.audit_asset_call_number_func and  auditor.audit_asset_copy_func
# Does not seem to have been set in: 2.1-2.2-b-upgrade-db.fix.sql call to select auditor.update_auditors() ;
# Evergreen missing two column references
# Box has two columns that point to corresponding tables.
#
# Action: added to patch.sql

# 5.7 CREATE FUNCTION flatten_marc(text)
# In Evergreen
# Box has no such function

# 5.8 CREATE FUNCTION generate_overlay_template(text, bigint) RETURNS text
# In Evergreen
# Box has no such function

# 5.9 CREATE OR REPLACE FUNCTION authority.normalize_heading( marcxml TEXT, no_thesaurus BOOL )
# Evergreen: oils_xpath('//*[contains("....
# Box: oils_xpath('./*[contains("....
# Not in update script.

# 5.10 CREATE FUNCTION marc21_extract_all_fixed_fields
# Evergreen: default to FALSE
# Box: defaults to TRUE
# Not in update script.

# 5.11 modify_metabib_field(v_source integer, target integer)
# Evergreen: exists, but dropped in 2.4.3-2.5.0-b-upgrade-db.fix.sql
# Box: not there

# 5.12 FUNCTION limit_oustl
# Not in Evergreen
# Box: is there                                                                                                     \

psql -f 999.seed.iish.sql


# Create reingest commands
mkdir -p reingest/authority
mkdir -p reingest/biblio
psql -f reingest.sql

cd reingest/authority
count=$(wc -l record_entry.sql | cut -f1 -d ' ')
lines=$(echo "($count + 8 - 1) / 8" | bc)
split -l $lines record_entry.sql

cd ../biblio
count=$(wc -l record_entry.sql | cut -f1 -d ' ')
lines=$(echo "($count + 8 - 1) / 8" | bc)
split -l $lines record_entry.sql

# 7. report templates
psql -f ../../../example.reporter-extension.sql



