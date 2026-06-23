-- biblio.add_902_uuid_trigger()
-- Voeg een 902a veld met een UUID toe aan de marc record.
CREATE OR REPLACE FUNCTION biblio.add_902_uuid_trigger()
RETURNS TRIGGER AS $$
DECLARE
    xml_record XML;
    upper_uuid TEXT;
    new_902_field XML;
    xml_string TEXT;
BEGIN
    -- Ensure we have a MARC XML record to manipulate. If not return here.
    IF NEW.marc IS NULL OR NEW.marc = '' THEN
        RETURN NEW;
END IF;

    xml_record := NEW.marc::XML;

    -- Check if a 902 datafield already exists to prevent duplicate injections
    IF NOT xpath_exists('//*[local-name()="datafield" and @tag="902"]', xml_record) THEN

        -- Generate an uppercase UUID v4
        upper_uuid := '10622' || '/' || UPPER(gen_random_uuid()::TEXT);

        -- Construct the 902 datafield XML node (using standard MARC21 blank indicators)
        new_902_field := XMLPARSE(DOCUMENT xmlelement(
            name "datafield",
            xmlattributes('902' as "tag", ' ' as "ind1", ' ' as "ind2"),
            xmlelement(name "subfield", xmlattributes('a' as "code"), upper_uuid)
        )::text);

        -- Cast XML to text to safely inject the node before the closing </record> tag
        xml_string := xml_record::TEXT;

        -- Append the new 902 datafield just prior to the end of the root record element
        xml_string := REGEXP_REPLACE(xml_string, '(</(?:[^:]+:)?record>)', new_902_field::TEXT || '\1', 'i');

        -- Assign the updated MARC XML document back to the incoming row
        NEW.marc := xml_string;
END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- create and attach add_902_uuid trigger to biblio.record_entry
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'd_add_902_uuid'
          AND tgrelid = 'biblio.record_entry'::regclass
    ) THEN
CREATE TRIGGER d_add_902_uuid
    BEFORE INSERT OR UPDATE ON biblio.record_entry
                         FOR EACH ROW
                         EXECUTE FUNCTION biblio.add_902_uuid_trigger();
END IF;
END;
$$;


-- authority.override_perl_leader_trigger()
-- Wijzig de hardcodes leader Open-ILS/src/perlmods/lib/OpenILS/Application/Cat/Authority.pm
CREATE OR REPLACE FUNCTION authority.override_perl_leader_trigger()
RETURNS TRIGGER AS $$
DECLARE
    xml_record XML;
    current_leader TEXT;
    target_leader TEXT;
    xml_string TEXT;
BEGIN
    -- Skip processing if the MARC payload is empty
    IF NEW.marc IS NULL OR NEW.marc = '' THEN
        RETURN NEW;
END IF;

    xml_record := NEW.marc::XML;

    -- Extract the current leader via XPath to check its validity
    current_leader := (xpath('//*[local-name()="leader"]/text()', xml_record))[1]::TEXT;

    -- Define your customized 24-character Authority Leader string override.
    -- Example layout for standard Authority record:
    -- Pos 00-04: 00000 (Placeholder length, updated by indexers)
    -- Pos 05: 'n' (New record)
    -- Pos 06: 'z' (Authority data type)
    -- Pos 09: 'a' (UCS/Unicode encoding)
    -- Pos 10-16: '2200000' (Indicator/subfield counts, standard base address)
    -- Pos 17: 'n' (National level encoding)
    -- Pos 18-23: '  4500' (Standard MARC21 entry map)
    target_leader := '00208nz  a22     o  4500';

    -- If a leader exists, perform a safe node substitution
    IF current_leader IS NOT NULL THEN
        xml_string := xml_record::TEXT;

        -- Directly replace the hardcoded text content inside the leader tag elements
        xml_string := replace(
            xml_string,
            '<leader>' || current_leader || '</leader>',
            '<leader>' || target_leader || '</leader>'
        );

        NEW.marc := xml_string;
ELSE
        -- Fallback: If Authority.pm completely omitted a <leader> element, inject it
        -- Prepend it right after the root namespace <record> opener tag
        xml_string := xml_record::TEXT;
        xml_string := REGEXP_REPLACE(
            xml_string,
            '(<(?:[^:]+:)?record[^>]*>)',
            '\1<leader>' || target_leader || '</leader>',
            'i'
        );

        NEW.marc := xml_string;
END IF;

RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- create and attach override_perl_leader trigger to authority.record_entry
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'd_override_perl_leader'
        AND tgrelid = 'authority.record_entry'::regclass
    ) THEN
CREATE TRIGGER d_override_perl_leader
    BEFORE INSERT OR UPDATE ON authority.record_entry
    FOR EACH ROW
    EXECUTE FUNCTION authority.override_perl_leader_trigger();
END IF;
END;
$$;