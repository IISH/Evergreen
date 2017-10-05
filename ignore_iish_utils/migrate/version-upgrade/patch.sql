BEGIN;


CREATE OR REPLACE FUNCTION auditor.audit_asset_call_number_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO auditor.asset_call_number_history ( audit_id, audit_time, audit_action, audit_user, audit_ws, id, creator, create_date, editor, edit_date, record, owning_lib, label, deleted, prefix, suffix, label_class, label_sortkey )
                SELECT  nextval('auditor.asset_call_number_pkey_seq'),
                    now(),
                    SUBSTR(TG_OP,1,1),
                    eg_user,
                    eg_ws,
                    OLD.id, OLD.creator, OLD.create_date, OLD.editor, OLD.edit_date, OLD.record, OLD.owning_lib, OLD.label, OLD.deleted, OLD.prefix, OLD.suffix, OLD.label_class, OLD.label_sortkey
                FROM auditor.get_audit_info();
            RETURN NULL;
        END;
        $$;



--
-- Name: audit_asset_copy_func(); Type: FUNCTION; Schema: auditor; Owner: concerto
--

CREATE OR REPLACE FUNCTION auditor.audit_asset_copy_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO auditor.asset_copy_history ( audit_id, audit_time, audit_action, audit_user, audit_ws, id, circ_lib, creator, call_number, editor, create_date, edit_date, copy_number, status, location, loan_duration, fine_level, age_protect, circulate, deposit, ref, holdable, deposit_amount, price, barcode, circ_modifier, circ_as_type, dummy_title, dummy_author, alert_message, opac_visible, deleted, floating, dummy_isbn, status_changed_time, active_date, mint_condition, cost )
                SELECT  nextval('auditor.asset_copy_pkey_seq'),
                    now(),
                    SUBSTR(TG_OP,1,1),
                    eg_user,
                    eg_ws,
                    OLD.id, OLD.circ_lib, OLD.creator, OLD.call_number, OLD.editor, OLD.create_date, OLD.edit_date, OLD.copy_number, OLD.status, OLD.location, OLD.loan_duration, OLD.fine_level, OLD.age_protect, OLD.circulate, OLD.deposit, OLD.ref, OLD.holdable, OLD.deposit_amount, OLD.price, OLD.barcode, OLD.circ_modifier, OLD.circ_as_type, OLD.dummy_title, OLD.dummy_author, OLD.alert_message, OLD.opac_visible, OLD.deleted, OLD.floating, OLD.dummy_isbn, OLD.status_changed_time, OLD.active_date, OLD.mint_condition, OLD.cost
                FROM auditor.get_audit_info();
            RETURN NULL;
        END;
        $$;


ALTER FUNCTION auditor.audit_asset_copy_func() OWNER TO evergreen;


CREATE OR REPLACE FUNCTION audit_serial_unit_func() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            INSERT INTO auditor.serial_unit_history ( audit_id, audit_time, audit_action, audit_user, audit_ws, id, circ_lib, creator, call_number, editor, create_date, edit_date, copy_number, status, location, loan_duration, fine_level, age_protect, circulate, deposit, ref, holdable, deposit_amount, price, barcode, circ_modifier, circ_as_type, dummy_title, dummy_author, alert_message, opac_visible, deleted, floating, dummy_isbn, status_changed_time, mint_condition, cost, active_date, sort_key, detailed_contents, summary_contents )
                SELECT  nextval('auditor.serial_unit_pkey_seq'),
                    now(),
                    SUBSTR(TG_OP,1,1),
                    eg_user,
                    eg_ws,
                    OLD.id, OLD.circ_lib, OLD.creator, OLD.call_number, OLD.editor, OLD.create_date, OLD.edit_date, OLD.copy_number, OLD.status, OLD.location, OLD.loan_duration, OLD.fine_level, OLD.age_protect, OLD.circulate, OLD.deposit, OLD.ref, OLD.holdable, OLD.deposit_amount, OLD.price, OLD.barcode, OLD.circ_modifier, OLD.circ_as_type, OLD.dummy_title, OLD.dummy_author, OLD.alert_message, OLD.opac_visible, OLD.deleted, OLD.floating, OLD.dummy_isbn, OLD.status_changed_time, OLD.mint_condition, OLD.cost, OLD.active_date, OLD.sort_key, OLD.detailed_contents, OLD.summary_contents
                FROM auditor.get_audit_info();
            RETURN NULL;
        END;
        $$;



CREATE OR REPLACE FUNCTION authority.normalize_heading( marcxml TEXT, no_thesaurus BOOL ) RETURNS TEXT AS $func$
DECLARE
    acsaf           authority.control_set_authority_field%ROWTYPE;
    tag_used        TEXT;
    nfi_used        TEXT;
    sf              TEXT;
    sf_node         TEXT;
    tag_node        TEXT;
    thes_code       TEXT;
    cset            INT;
    heading_text    TEXT;
    tmp_text        TEXT;
    first_sf        BOOL;
    auth_id         INT DEFAULT COALESCE(NULLIF(oils_xpath_string('//*[@tag="901"]/*[local-name()="subfield" and @code="c"]', marcxml), ''), '0')::INT;
BEGIN
    SELECT control_set INTO cset FROM authority.record_entry WHERE id = auth_id;

    IF cset IS NULL THEN
        SELECT  control_set INTO cset
          FROM  authority.control_set_authority_field
          WHERE tag IN ( SELECT  UNNEST(XPATH('//*[starts-with(@tag,"1")]/@tag',marcxml::XML)::TEXT[]))
          LIMIT 1;
    END IF;

    thes_code := vandelay.marc21_extract_fixed_field(marcxml,'Subj');
    IF thes_code IS NULL THEN
        thes_code := '|';
    ELSIF thes_code = 'z' THEN
        thes_code := COALESCE( oils_xpath_string('//*[@tag="040"]/*[@code="f"][1]', marcxml), '' );
    END IF;

    heading_text := '';
    FOR acsaf IN SELECT * FROM authority.control_set_authority_field WHERE control_set = cset AND main_entry IS NULL LOOP
        tag_used := acsaf.tag;
        nfi_used := acsaf.nfi;
        first_sf := TRUE;

        FOR tag_node IN SELECT unnest(oils_xpath('//*[@tag="'||tag_used||'"]',marcxml)) LOOP
            FOR sf_node IN SELECT unnest(oils_xpath('./*[contains("'||acsaf.sf_list||'",@code)]',tag_node)) LOOP

                tmp_text := oils_xpath_string('.', sf_node);
                sf := oils_xpath_string('./@code', sf_node);

                IF first_sf AND tmp_text IS NOT NULL AND nfi_used IS NOT NULL THEN

                    tmp_text := SUBSTRING(
                        tmp_text FROM
                        COALESCE(
                            NULLIF(
                                REGEXP_REPLACE(
                                    oils_xpath_string('./@ind'||nfi_used, tag_node),
                                    $$\D+$$,
                                    '',
                                    'g'
                                ),
                                ''
                            )::INT,
                            0
                        ) + 1
                    );

                END IF;

                first_sf := FALSE;

                IF tmp_text IS NOT NULL AND tmp_text <> '' THEN
                    heading_text := heading_text || E'\u2021' || sf || ' ' || tmp_text;
                END IF;
            END LOOP;

            EXIT WHEN heading_text <> '';
        END LOOP;

        EXIT WHEN heading_text <> '';
    END LOOP;

    IF heading_text <> '' THEN
        IF no_thesaurus IS TRUE THEN
            heading_text := tag_used || ' ' || public.naco_normalize(heading_text);
        ELSE
            heading_text := tag_used || '_' || COALESCE(nfi_used,'-') || '_' || thes_code || ' ' || public.naco_normalize(heading_text);
        END IF;
    ELSE
        heading_text := 'NOHEADING_' || thes_code || ' ' || MD5(marcxml);
    END IF;

    RETURN heading_text;
END;
$func$ LANGUAGE PLPGSQL STABLE STRICT;

ROLLBACK ;