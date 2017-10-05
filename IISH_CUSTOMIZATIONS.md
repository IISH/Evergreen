#What is different from the Evergreen main branch 2.7.1 ?

These are additions and changes on top of branch 2.7.1

##Templates for new records
Added to Open-ILS/src/templates/marc/*.xml

##Authority.pm
Open-ILS/src/perlmods/lib/OpenILS/Application/Cat/Authority.pm

###create_authority_record_from_bib_field

Adds a default to the leader

## Added new modules OAI, Batch and Handle
Open-ILS/src/perlmods/lib/OpenILS/Application/OAI.pm with WWW/OAI.pm

Open-ILS/src/perlmods/lib/OpenILS/Application/Handle.pm

Open-ILS/src/perlmods/lib/OpenILS/Application/Batch.pm with WWW/Batch.pm

##fm_IDL.xml
Open-ILS/examples/fm_IDL.xml

Added a new source "xslt" to allow for a marcxml-to-column mapping for reporting.

Added a new source "oai.record" for the OAI service.

Added a new source "batch.schedule" for the bulk update service.

##Seeds, views and tables

# xslt documents
Open-ILS/src/sql/Pg/999.seed.iish.sql
