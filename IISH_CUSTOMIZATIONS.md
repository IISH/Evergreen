# Additions to the Evergreen main branch

##Templates for new records marc and opac templates

    Added to Open-ILS/src/templates_iish

##Authority.pm leader

    Open-ILS/src/perlmods/lib/OpenILS/Application/Cat/Authority.pm

## BibCommon.pm 902 field

    Open-ILS/src/perlmods/lib/OpenILS/Application/Cat/BibCommon.pm

Adds a default to the leader

## Added new modules OAI, Batch and Handle

    Open-ILS/src/perlmods/lib/OpenILS/Application/OAI.pm
    Open-ILS/src/perlmods/lib/OpenILS/WWW/OAI.pm

    Open-ILS/src/perlmods/lib/OpenILS/Application/Handle.pm

    Open-ILS/src/perlmods/lib/OpenILS/Application/BatchEnrich.pm
    Open-ILS/src/perlmods/lib/OpenILS/WWW/BatchEnrich.pm
        
    Open-ILS/src/perlmods/lib/OpenILS/Application/BatchUpdate.pm
    Open-ILS/src/perlmods/lib/OpenILS/WWW/BatchUpdate.pm

## Archive web page

    Open-ILS/src/perlmods/lib/OpenILS/WWW/Archive.pm

##fm_IDL.xml

    Open-ILS/examples/fm_IDL.xml

Added a new source "xslt" to allow for a marcxml-to-column mapping for reporting.

Added a new source "oai.record" for the OAI service.

Added a new source "batch.schedule" for the bulk update service.

##Seeds, views and tables

# xslt documents

    Open-ILS/src/sql/Pg/999.seed.iish.sql
