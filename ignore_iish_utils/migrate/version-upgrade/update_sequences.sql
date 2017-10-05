SELECT SETVAL('actor.address_alert_id_seq', COALESCE(MAX(id), 1) ) FROM actor.address_alert;
SELECT SETVAL('action.archive_actor_stat_cat_id_seq', COALESCE(MAX(id), 1) ) FROM action.archive_actor_stat_cat;
SELECT SETVAL('action.archive_asset_stat_cat_id_seq', COALESCE(MAX(id), 1) ) FROM action.archive_asset_stat_cat;
SELECT SETVAL('metabib.author_field_entry_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.author_field_entry;
SELECT SETVAL('vandelay.authority_attr_definition_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.authority_attr_definition;
SELECT SETVAL('vandelay.authority_match_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.authority_match;
SELECT SETVAL('config.barcode_completion_id_seq', COALESCE(MAX(id), 1) ) FROM config.barcode_completion;
SELECT SETVAL('serial.basic_summary_id_seq', COALESCE(MAX(id), 1) ) FROM serial.basic_summary;
SELECT SETVAL('vandelay.bib_attr_definition_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.bib_attr_definition;
SELECT SETVAL('authority.bib_linking_id_seq', COALESCE(MAX(id), 1) ) FROM authority.bib_linking;
SELECT SETVAL('vandelay.bib_match_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.bib_match;
SELECT SETVAL('config.bib_source_id_seq', COALESCE(MAX(id), 1) ) FROM config.bib_source;
SELECT SETVAL('config.biblio_fingerprint_id_seq', COALESCE(MAX(id), 1) ) FROM config.biblio_fingerprint;
SELECT SETVAL('container.biblio_record_entry_bucket_id_seq', COALESCE(MAX(id), 1) ) FROM container.biblio_record_entry_bucket;
SELECT SETVAL('container.biblio_record_entry_bucket_item_id_seq', COALESCE(MAX(id), 1) ) FROM container.biblio_record_entry_bucket_item;
SELECT SETVAL('container.biblio_record_entry_bucket_item_note_id_seq', COALESCE(MAX(id), 1) ) FROM container.biblio_record_entry_bucket_item_note;
SELECT SETVAL('container.biblio_record_entry_bucket_note_id_seq', COALESCE(MAX(id), 1) ) FROM container.biblio_record_entry_bucket_note;
SELECT SETVAL('money.billable_xact_id_seq', COALESfCE(MAX(id), 1) ) FROM money.billable_xact;
SELECT SETVAL('money.billing_id_seq', COALESCE(MAX(id), 1) ) FROM money.billing;
SELECT SETVAL('config.billing_type_id_seq', COALESCE(MAX(id), 1) ) FROM config.billing_type;
SELECT SETVAL('authority.browse_axis_authority_field_map_id_seq', COALESCE(MAX(id), 1) ) FROM authority.browse_axis_authority_field_map;
SELECT SETVAL('metabib.browse_entry_def_map_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.browse_entry_def_map;
SELECT SETVAL('metabib.browse_entry_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.browse_entry;
SELECT SETVAL('container.call_number_bucket_id_seq', COALESCE(MAX(id), 1) ) FROM container.call_number_bucket;
SELECT SETVAL('container.call_number_bucket_item_id_seq', COALESCE(MAX(id), 1) ) FROM container.call_number_bucket_item;
SELECT SETVAL('container.call_number_bucket_item_note_id_seq', COALESCE(MAX(id), 1) ) FROM container.call_number_bucket_item_note;
SELECT SETVAL('container.call_number_bucket_note_id_seq', COALESCE(MAX(id), 1) ) FROM container.call_number_bucket_note;
SELECT SETVAL('asset.call_number_class_id_seq', COALESCE(MAX(id), 1) ) FROM asset.call_number_class;
SELECT SETVAL('asset.call_number_id_seq', COALESCE(MAX(id), 1) ) FROM asset.call_number;
SELECT SETVAL('asset.call_number_note_id_seq', COALESCE(MAX(id), 1) ) FROM asset.call_number_note;
SELECT SETVAL('asset.call_number_prefix_id_seq', COALESCE(MAX(id), 1) ) FROM asset.call_number_prefix;
SELECT SETVAL('asset.call_number_suffix_id_seq', COALESCE(MAX(id), 1) ) FROM asset.call_number_suffix;
SELECT SETVAL('acq.cancel_reason_id_seq', COALESCE(MAX(id), 1) ) FROM acq.cancel_reason;
SELECT SETVAL('serial.caption_and_pattern_id_seq', COALESCE(MAX(id), 1) ) FROM serial.caption_and_pattern;
SELECT SETVAL('actor.card_id_seq', COALESCE(MAX(id), 1) ) FROM actor.card;
SELECT SETVAL('staging.card_stage_row_id_seq', COALESCE(MAX(row_id), 1) ) FROM staging.card_stage;
SELECT SETVAL('query.case_branch_id_seq', COALESCE(MAX(id), 1) ) FROM query.case_branch;
SELECT SETVAL('config.circ_limit_group_id_seq', COALESCE(MAX(id), 1) ) FROM config.circ_limit_group;
SELECT SETVAL('config.circ_limit_set_circ_mod_map_id_seq', COALESCE(MAX(id), 1) ) FROM config.circ_limit_set_circ_mod_map;
SELECT SETVAL('config.circ_limit_set_group_map_id_seq', COALESCE(MAX(id), 1) ) FROM config.circ_limit_set_group_map;
SELECT SETVAL('config.circ_limit_set_id_seq', COALESCE(MAX(id), 1) ) FROM config.circ_limit_set;
SELECT SETVAL('config.circ_matrix_circ_mod_test_id_seq', COALESCE(MAX(id), 1) ) FROM config.circ_matrix_circ_mod_test;
SELECT SETVAL('config.circ_matrix_circ_mod_test_map_id_seq', COALESCE(MAX(id), 1) ) FROM config.circ_matrix_circ_mod_test_map;
SELECT SETVAL('config.circ_matrix_limit_set_map_id_seq', COALESCE(MAX(id), 1) ) FROM config.circ_matrix_limit_set_map;
SELECT SETVAL('config.circ_matrix_matchpoint_id_seq', COALESCE(MAX(id), 1) ) FROM config.circ_matrix_matchpoint;
SELECT SETVAL('config.circ_matrix_weights_id_seq', COALESCE(MAX(id), 1) ) FROM config.circ_matrix_weights;
SELECT SETVAL('acq.claim_event_claim_seq', COALESCE(MAX(claim), 1) ) FROM acq.claim_event;
SELECT SETVAL('acq.claim_event_id_seq', COALESCE(MAX(id), 1) ) FROM acq.claim_event;
SELECT SETVAL('acq.claim_event_type_id_seq', COALESCE(MAX(id), 1) ) FROM acq.claim_event_type;
SELECT SETVAL('acq.claim_id_seq', COALESCE(MAX(id), 1) ) FROM acq.claim;
SELECT SETVAL('acq.claim_policy_action_id_seq', COALESCE(MAX(id), 1) ) FROM acq.claim_policy_action;
SELECT SETVAL('acq.claim_policy_id_seq', COALESCE(MAX(id), 1) ) FROM acq.claim_policy;
SELECT SETVAL('acq.claim_type_id_seq', COALESCE(MAX(id), 1) ) FROM acq.claim_type;
SELECT SETVAL('config.coded_value_map_id_seq', COALESCE(MAX(id), 1) ) FROM config.coded_value_map;
SELECT SETVAL('money.collections_tracker_id_seq', COALESCE(MAX(id), 1) ) FROM money.collections_tracker;
SELECT SETVAL('authority.control_set_authority_field_id_seq', COALESCE(MAX(id), 1) ) FROM authority.control_set_authority_field;
SELECT SETVAL('authority.control_set_bib_field_id_seq', COALESCE(MAX(id), 1) ) FROM authority.control_set_bib_field;
SELECT SETVAL('authority.control_set_id_seq', COALESCE(MAX(id), 1) ) FROM authority.control_set;
SELECT SETVAL('container.copy_bucket_id_seq', COALESCE(MAX(id), 1) ) FROM container.copy_bucket;
SELECT SETVAL('container.copy_bucket_item_id_seq', COALESCE(MAX(id), 1) ) FROM container.copy_bucket_item;
SELECT SETVAL('container.copy_bucket_item_note_id_seq', COALESCE(MAX(id), 1) ) FROM container.copy_bucket_item_note;
SELECT SETVAL('container.copy_bucket_note_id_seq', COALESCE(MAX(id), 1) ) FROM container.copy_bucket_note;
SELECT SETVAL('asset.copy_id_seq', COALESCE(MAX(id), 1) ) FROM asset.copy;
SELECT SETVAL('asset.copy_location_group_id_seq', COALESCE(MAX(id), 1) ) FROM asset.copy_location_group;
SELECT SETVAL('asset.copy_location_group_map_id_seq', COALESCE(MAX(id), 1) ) FROM asset.copy_location_group_map;
SELECT SETVAL('asset.copy_location_id_seq', COALESCE(MAX(id), 1) ) FROM asset.copy_location;
SELECT SETVAL('asset.copy_location_order_id_seq', COALESCE(MAX(id), 1) ) FROM asset.copy_location_order;
SELECT SETVAL('asset.copy_note_id_seq', COALESCE(MAX(id), 1) ) FROM asset.copy_note;
SELECT SETVAL('asset.copy_part_map_id_seq', COALESCE(MAX(id), 1) ) FROM asset.copy_part_map;
SELECT SETVAL('config.copy_status_id_seq', COALESCE(MAX(id), 1) ) FROM config.copy_status;
SELECT SETVAL('asset.copy_template_id_seq', COALESCE(MAX(id), 1) ) FROM asset.copy_template;
SELECT SETVAL('query.datatype_id_seq', COALESCE(MAX(id), 1) ) FROM query.datatype;
SELECT SETVAL('acq.distribution_formula_application_id_seq', COALESCE(MAX(id), 1) ) FROM acq.distribution_formula_application;
SELECT SETVAL('acq.distribution_formula_entry_id_seq', COALESCE(MAX(id), 1) ) FROM acq.distribution_formula_entry;
SELECT SETVAL('acq.distribution_formula_id_seq', COALESCE(MAX(id), 1) ) FROM acq.distribution_formula;
SELECT SETVAL('serial.distribution_id_seq', COALESCE(MAX(id), 1) ) FROM serial.distribution;
SELECT SETVAL('serial.distribution_note_id_seq', COALESCE(MAX(id), 1) ) FROM serial.distribution_note;
SELECT SETVAL('acq.edi_message_id_seq', COALESCE(MAX(id), 1) ) FROM acq.edi_message;
SELECT SETVAL('action_trigger.environment_id_seq', COALESCE(MAX(id), 1) ) FROM action_trigger.environment;
SELECT SETVAL('action_trigger.event_definition_id_seq', COALESCE(MAX(id), 1) ) FROM action_trigger.event_definition;
SELECT SETVAL('action_trigger.event_id_seq', COALESCE(MAX(id), 1) ) FROM action_trigger.event;
SELECT SETVAL('action_trigger.event_output_id_seq', COALESCE(MAX(id), 1) ) FROM action_trigger.event_output;
SELECT SETVAL('action_trigger.event_params_id_seq', COALESCE(MAX(id), 1) ) FROM action_trigger.event_params;
SELECT SETVAL('acq.exchange_rate_id_seq', COALESCE(MAX(id), 1) ) FROM acq.exchange_rate;
SELECT SETVAL('query.expression_id_seq', COALESCE(MAX(id), 1) ) FROM query.expression;
SELECT SETVAL('metabib.facet_entry_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.facet_entry;
SELECT SETVAL('action.fieldset_col_val_id_seq', COALESCE(MAX(id), 1) ) FROM action.fieldset_col_val;
SELECT SETVAL('action.fieldset_id_seq', COALESCE(MAX(id), 1) ) FROM action.fieldset;
SELECT SETVAL('acq.fiscal_calendar_id_seq', COALESCE(MAX(id), 1) ) FROM acq.fiscal_calendar;
SELECT SETVAL('acq.fiscal_year_id_seq', COALESCE(MAX(id), 1) ) FROM acq.fiscal_year;
SELECT SETVAL('query.from_relation_id_seq', COALESCE(MAX(id), 1) ) FROM query.from_relation;
SELECT SETVAL('authority.full_rec_id_seq', COALESCE(MAX(id), 1) ) FROM authority.full_rec;
SELECT SETVAL('query.function_param_def_id_seq', COALESCE(MAX(id), 1) ) FROM query.function_param_def;
SELECT SETVAL('query.function_sig_id_seq', COALESCE(MAX(id), 1) ) FROM query.function_sig;
SELECT SETVAL('acq.fund_allocation_id_seq', COALESCE(MAX(id), 1) ) FROM acq.fund_allocation;
SELECT SETVAL('acq.fund_allocation_percent_id_seq', COALESCE(MAX(id), 1) ) FROM acq.fund_allocation_percent;
SELECT SETVAL('acq.fund_debit_id_seq', COALESCE(MAX(id), 1) ) FROM acq.fund_debit;
SELECT SETVAL('acq.fund_id_seq', COALESCE(MAX(id), 1) ) FROM acq.fund;
SELECT SETVAL('acq.fund_tag_id_seq', COALESCE(MAX(id), 1) ) FROM acq.fund_tag;
SELECT SETVAL('acq.fund_tag_map_id_seq', COALESCE(MAX(id), 1) ) FROM acq.fund_tag_map;
SELECT SETVAL('acq.fund_transfer_id_seq', COALESCE(MAX(id), 1) ) FROM acq.fund_transfer;
SELECT SETVAL('acq.funding_source_credit_id_seq', COALESCE(MAX(id), 1) ) FROM acq.funding_source_credit;
SELECT SETVAL('acq.funding_source_id_seq', COALESCE(MAX(id), 1) ) FROM acq.funding_source;
SELECT SETVAL('permission.grp_penalty_threshold_id_seq', COALESCE(MAX(id), 1) ) FROM permission.grp_penalty_threshold;
SELECT SETVAL('permission.grp_perm_map_id_seq', COALESCE(MAX(id), 1) ) FROM permission.grp_perm_map;
SELECT SETVAL('permission.grp_tree_id_seq', COALESCE(MAX(id), 1) ) FROM permission.grp_tree;
SELECT SETVAL('config.hard_due_date_id_seq', COALESCE(MAX(id), 1) ) FROM config.hard_due_date;
SELECT SETVAL('config.hard_due_date_values_id_seq', COALESCE(MAX(id), 1) ) FROM config.hard_due_date_values;
SELECT SETVAL('action.hold_copy_map_id_seq', COALESCE(MAX(id), 1) ) FROM action.hold_copy_map;
SELECT SETVAL('config.hold_matrix_matchpoint_id_seq', COALESCE(MAX(id), 1) ) FROM config.hold_matrix_matchpoint;
SELECT SETVAL('config.hold_matrix_weights_id_seq', COALESCE(MAX(id), 1) ) FROM config.hold_matrix_weights;
SELECT SETVAL('action.hold_notification_id_seq', COALESCE(MAX(id), 1) ) FROM action.hold_notification;
SELECT SETVAL('action.hold_request_cancel_cause_id_seq', COALESCE(MAX(id), 1) ) FROM action.hold_request_cancel_cause;
SELECT SETVAL('action.hold_request_id_seq', COALESCE(MAX(id), 1) ) FROM action.hold_request;
SELECT SETVAL('action.hold_request_note_id_seq', COALESCE(MAX(id), 1) ) FROM action.hold_request_note;
SELECT SETVAL('config.i18n_core_id_seq', COALESCE(MAX(id), 1) ) FROM config.i18n_core;
SELECT SETVAL('config.identification_type_id_seq', COALESCE(MAX(id), 1) ) FROM config.identification_type;
SELECT SETVAL('metabib.identifier_field_entry_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.identifier_field_entry;
SELECT SETVAL('config.idl_field_doc_id_seq', COALESCE(MAX(id), 1) ) FROM config.idl_field_doc;
SELECT SETVAL('vandelay.import_bib_trash_fields_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.import_bib_trash_fields;
SELECT SETVAL('vandelay.import_item_attr_definition_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.import_item_attr_definition;
SELECT SETVAL('vandelay.import_item_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.import_item;
SELECT SETVAL('action.in_house_use_id_seq', COALESCE(MAX(id), 1) ) FROM action.in_house_use;
SELECT SETVAL('config.index_normalizer_id_seq', COALESCE(MAX(id), 1) ) FROM config.index_normalizer;
SELECT SETVAL('serial.index_summary_id_seq', COALESCE(MAX(id), 1) ) FROM serial.index_summary;
SELECT SETVAL('acq.invoice_entry_id_seq', COALESCE(MAX(id), 1) ) FROM acq.invoice_entry;
SELECT SETVAL('acq.invoice_id_seq', COALESCE(MAX(id), 1) ) FROM acq.invoice;
SELECT SETVAL('acq.invoice_item_id_seq', COALESCE(MAX(id), 1) ) FROM acq.invoice_item;
SELECT SETVAL('serial.issuance_id_seq', COALESCE(MAX(id), 1) ) FROM serial.issuance;
SELECT SETVAL('serial.item_id_seq', COALESCE(MAX(id), 1) ) FROM serial.item;
SELECT SETVAL('serial.item_note_id_seq', COALESCE(MAX(id), 1) ) FROM serial.item_note;
SELECT SETVAL('metabib.keyword_field_entry_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.keyword_field_entry;
SELECT SETVAL('acq.lineitem_alert_text_id_seq', COALESCE(MAX(id), 1) ) FROM acq.lineitem_alert_text;
SELECT SETVAL('acq.lineitem_attr_definition_id_seq', COALESCE(MAX(id), 1) ) FROM acq.lineitem_attr_definition;
SELECT SETVAL('acq.lineitem_attr_id_seq', COALESCE(MAX(id), 1) ) FROM acq.lineitem_attr;
SELECT SETVAL('acq.lineitem_detail_id_seq', COALESCE(MAX(id), 1) ) FROM acq.lineitem_detail;
SELECT SETVAL('acq.lineitem_id_seq', COALESCE(MAX(id), 1) ) FROM acq.lineitem;
SELECT SETVAL('acq.lineitem_note_id_seq', COALESCE(MAX(id), 1) ) FROM acq.lineitem_note;
SELECT SETVAL('staging.mailing_address_stage_row_id_seq', COALESCE(MAX(row_id), 1) ) FROM staging.mailing_address_stage;
SELECT SETVAL('config.marc21_ff_pos_map_id_seq', COALESCE(MAX(id), 1) ) FROM config.marc21_ff_pos_map;
SELECT SETVAL('config.marc21_physical_characteristic_subfield_map_id_seq', COALESCE(MAX(id), 1) ) FROM config.marc21_physical_characteristic_subfield_map;
SELECT SETVAL('config.marc21_physical_characteristic_value_map_id_seq', COALESCE(MAX(id), 1) ) FROM config.marc21_physical_characteristic_value_map;
SELECT SETVAL('vandelay.match_set_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.match_set;
SELECT SETVAL('vandelay.match_set_point_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.match_set_point;
SELECT SETVAL('vandelay.match_set_quality_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.match_set_quality;
SELECT SETVAL('serial.materialized_holding_code_id_seq', COALESCE(MAX(id), 1) ) FROM serial.materialized_holding_code;
SELECT SETVAL('vandelay.merge_profile_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.merge_profile;
SELECT SETVAL('config.metabib_field_id_seq', COALESCE(MAX(id), 1) ) FROM config.metabib_field;
SELECT SETVAL('config.metabib_field_index_norm_map_id_seq', COALESCE(MAX(id), 1) ) FROM config.metabib_field_index_norm_map;
SELECT SETVAL('metabib.metarecord_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.metarecord;
SELECT SETVAL('metabib.metarecord_source_map_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.metarecord_source_map;
SELECT SETVAL('biblio.monograph_part_id_seq', COALESCE(MAX(id), 1) ) FROM biblio.monograph_part;
SELECT SETVAL('config.net_access_level_id_seq', COALESCE(MAX(id), 1) ) FROM config.net_access_level;
SELECT SETVAL('action.non_cat_in_house_use_id_seq', COALESCE(MAX(id), 1) ) FROM action.non_cat_in_house_use;
SELECT SETVAL('action.non_cataloged_circulation_id_seq', COALESCE(MAX(id), 1) ) FROM action.non_cataloged_circulation;
SELECT SETVAL('config.non_cataloged_type_id_seq', COALESCE(MAX(id), 1) ) FROM config.non_cataloged_type;
SELECT SETVAL('asset.opac_visible_copies_id_seq', COALESCE(MAX(id), 1) ) FROM asset.opac_visible_copies;
SELECT SETVAL('query.order_by_item_id_seq', COALESCE(MAX(id), 1) ) FROM query.order_by_item;
SELECT SETVAL('actor.org_address_id_seq', COALESCE(MAX(id), 1) ) FROM actor.org_address;
SELECT SETVAL('actor.org_lasso_id_seq', COALESCE(MAX(id), 1) ) FROM actor.org_lasso;
SELECT SETVAL('actor.org_lasso_map_id_seq', COALESCE(MAX(id), 1) ) FROM actor.org_lasso_map;
SELECT SETVAL('actor.org_unit_closed_id_seq', COALESCE(MAX(id), 1) ) FROM actor.org_unit_closed;
SELECT SETVAL('actor.org_unit_custom_tree_id_seq', COALESCE(MAX(id), 1) ) FROM actor.org_unit_custom_tree;
SELECT SETVAL('actor.org_unit_custom_tree_node_id_seq', COALESCE(MAX(id), 1) ) FROM actor.org_unit_custom_tree_node;
SELECT SETVAL('actor.org_unit_id_seq', COALESCE(MAX(id), 1) ) FROM actor.org_unit;
SELECT SETVAL('actor.org_unit_proximity_id_seq', COALESCE(MAX(id), 1) ) FROM actor.org_unit_proximity;
SELECT SETVAL('actor.org_unit_setting_id_seq', COALESCE(MAX(id), 1) ) FROM actor.org_unit_setting;
SELECT SETVAL('config.org_unit_setting_type_log_id_seq', COALESCE(MAX(id), 1) ) FROM config.org_unit_setting_type_log;
SELECT SETVAL('actor.org_unit_type_id_seq', COALESCE(MAX(id), 1) ) FROM actor.org_unit_type;
SELECT SETVAL('reporter.output_folder_id_seq', COALESCE(MAX(id), 1) ) FROM reporter.output_folder;
SELECT SETVAL('money.payment_id_seq', COALESCE(MAX(id), 1) ) FROM money.payment;
SELECT SETVAL('biblio.peer_bib_copy_map_id_seq', COALESCE(MAX(id), 1) ) FROM biblio.peer_bib_copy_map;
SELECT SETVAL('biblio.peer_type_id_seq', COALESCE(MAX(id), 1) ) FROM biblio.peer_type;
SELECT SETVAL('permission.perm_list_id_seq', COALESCE(MAX(id), 1) ) FROM permission.perm_list;
SELECT SETVAL('acq.picklist_id_seq', COALESCE(MAX(id), 1) ) FROM acq.picklist;
SELECT SETVAL('acq.po_item_id_seq', COALESCE(MAX(id), 1) ) FROM acq.po_item;
SELECT SETVAL('acq.po_note_id_seq', COALESCE(MAX(id), 1) ) FROM acq.po_note;
SELECT SETVAL('acq.provider_address_id_seq', COALESCE(MAX(id), 1) ) FROM acq.provider_address;
SELECT SETVAL('acq.provider_contact_address_id_seq', COALESCE(MAX(id), 1) ) FROM acq.provider_contact_address;
SELECT SETVAL('acq.provider_contact_id_seq', COALESCE(MAX(id), 1) ) FROM acq.provider_contact;
SELECT SETVAL('acq.provider_holding_subfield_map_id_seq', COALESCE(MAX(id), 1) ) FROM acq.provider_holding_subfield_map;
SELECT SETVAL('acq.provider_id_seq', COALESCE(MAX(id), 1) ) FROM acq.provider;
SELECT SETVAL('acq.provider_note_id_seq', COALESCE(MAX(id), 1) ) FROM acq.provider_note;
SELECT SETVAL('acq.purchase_order_id_seq', COALESCE(MAX(id), 1) ) FROM acq.purchase_order;
SELECT SETVAL('query.query_sequence_id_seq', COALESCE(MAX(id), 1) ) FROM query.query_sequence;
SELECT SETVAL('vandelay.queue_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.queue;
SELECT SETVAL('vandelay.queued_authority_record_attr_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.queued_authority_record_attr;
SELECT SETVAL('vandelay.queued_bib_record_attr_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.queued_bib_record_attr;
SELECT SETVAL('vandelay.queued_record_id_seq', COALESCE(MAX(id), 1) ) FROM vandelay.queued_record;
SELECT SETVAL('authority.rec_descriptor_id_seq', COALESCE(MAX(id), 1) ) FROM authority.rec_descriptor;
SELECT SETVAL('config.record_attr_index_norm_map_id_seq', COALESCE(MAX(id), 1) ) FROM config.record_attr_index_norm_map;
SELECT SETVAL('query.record_column_id_seq', COALESCE(MAX(id), 1) ) FROM query.record_column;
SELECT SETVAL('serial.record_entry_id_seq', COALESCE(MAX(id), 1) ) FROM serial.record_entry;
SELECT SETVAL('serial.record_entry_id_seq', COALESCE(MAX(id), 1) ) FROM serial.record_entry;
SELECT SETVAL('biblio.record_entry_id_seq', COALESCE(MAX(id), 1) ) FROM biblio.record_entry;
SELECT SETVAL('authority.record_entry_id_seq', COALESCE(MAX(id), 1) ) FROM authority.record_entry;
SELECT SETVAL('serial.record_entry_id_seq', COALESCE(MAX(id), 1) ) FROM serial.record_entry;
SELECT SETVAL('biblio.record_entry_id_seq', COALESCE(MAX(id), 1) ) FROM biblio.record_entry;
SELECT SETVAL('authority.record_entry_id_seq', COALESCE(MAX(id), 1) ) FROM authority.record_entry;
SELECT SETVAL('biblio.record_entry_id_seq', COALESCE(MAX(id), 1) ) FROM biblio.record_entry;
SELECT SETVAL('authority.record_entry_id_seq', COALESCE(MAX(id), 1) ) FROM authority.record_entry;
SELECT SETVAL('biblio.record_note_id_seq', COALESCE(MAX(id), 1) ) FROM biblio.record_note;
SELECT SETVAL('biblio.record_note_id_seq', COALESCE(MAX(id), 1) ) FROM biblio.record_note;
SELECT SETVAL('authority.record_note_id_seq', COALESCE(MAX(id), 1) ) FROM authority.record_note;
SELECT SETVAL('authority.record_note_id_seq', COALESCE(MAX(id), 1) ) FROM authority.record_note;
SELECT SETVAL('search.relevance_adjustment_id_seq', COALESCE(MAX(id), 1) ) FROM search.relevance_adjustment;
SELECT SETVAL('config.remote_account_id_seq', COALESCE(MAX(id), 1) ) FROM config.remote_account;
SELECT SETVAL('reporter.report_folder_id_seq', COALESCE(MAX(id), 1) ) FROM reporter.report_folder;
SELECT SETVAL('reporter.report_id_seq', COALESCE(MAX(id), 1) ) FROM reporter.report;
SELECT SETVAL('booking.reservation_attr_value_map_id_seq', COALESCE(MAX(id), 1) ) FROM booking.reservation_attr_value_map;
SELECT SETVAL('booking.resource_attr_id_seq', COALESCE(MAX(id), 1) ) FROM booking.resource_attr;
SELECT SETVAL('booking.resource_attr_map_id_seq', COALESCE(MAX(id), 1) ) FROM booking.resource_attr_map;
SELECT SETVAL('booking.resource_attr_value_id_seq', COALESCE(MAX(id), 1) ) FROM booking.resource_attr_value;
SELECT SETVAL('booking.resource_id_seq', COALESCE(MAX(id), 1) ) FROM booking.resource;
SELECT SETVAL('booking.resource_type_id_seq', COALESCE(MAX(id), 1) ) FROM booking.resource_type;
SELECT SETVAL('serial.routing_list_user_id_seq', COALESCE(MAX(id), 1) ) FROM serial.routing_list_user;
SELECT SETVAL('config.rule_age_hold_protect_id_seq', COALESCE(MAX(id), 1) ) FROM config.rule_age_hold_protect;
SELECT SETVAL('config.rule_circ_duration_id_seq', COALESCE(MAX(id), 1) ) FROM config.rule_circ_duration;
SELECT SETVAL('config.rule_max_fine_id_seq', COALESCE(MAX(id), 1) ) FROM config.rule_max_fine;
SELECT SETVAL('config.rule_recurring_fine_id_seq', COALESCE(MAX(id), 1) ) FROM config.rule_recurring_fine;
SELECT SETVAL('reporter.schedule_id_seq', COALESCE(MAX(id), 1) ) FROM reporter.schedule;
SELECT SETVAL('offline.script_id_seq', COALESCE(MAX(id), 1) ) FROM offline.script;
SELECT SETVAL('query.select_item_id_seq', COALESCE(MAX(id), 1) ) FROM query.select_item;
SELECT SETVAL('acq.serial_claim_event_claim_seq', COALESCE(MAX(claim), 1) ) FROM acq.serial_claim_event;
SELECT SETVAL('acq.serial_claim_event_id_seq', COALESCE(MAX(id), 1) ) FROM acq.serial_claim_event;
SELECT SETVAL('acq.serial_claim_id_seq', COALESCE(MAX(id), 1) ) FROM acq.serial_claim;
SELECT SETVAL('metabib.series_field_entry_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.series_field_entry;
SELECT SETVAL('authority.simple_heading_id_seq', COALESCE(MAX(id), 1) ) FROM authority.simple_heading;
SELECT SETVAL('config.sms_carrier_id_seq', COALESCE(MAX(id), 1) ) FROM config.sms_carrier;
SELECT SETVAL('config.standing_id_seq', COALESCE(MAX(id), 1) ) FROM config.standing;
SELECT SETVAL('config.standing_penalty_id_seq', COALESCE(MAX(id), 1) ) FROM config.standing_penalty;
SELECT SETVAL('asset.stat_cat_entry_copy_map_id_seq', COALESCE(MAX(id), 1) ) FROM asset.stat_cat_entry_copy_map;
SELECT SETVAL('actor.stat_cat_entry_default_id_seq', COALESCE(MAX(id), 1) ) FROM actor.stat_cat_entry_default;
SELECT SETVAL('asset.stat_cat_entry_id_seq', COALESCE(MAX(id), 1) ) FROM asset.stat_cat_entry;
SELECT SETVAL('actor.stat_cat_entry_id_seq', COALESCE(MAX(id), 1) ) FROM actor.stat_cat_entry;
SELECT SETVAL('actor.stat_cat_entry_id_seq', COALESCE(MAX(id), 1) ) FROM actor.stat_cat_entry;
SELECT SETVAL('asset.stat_cat_entry_id_seq', COALESCE(MAX(id), 1) ) FROM asset.stat_cat_entry;
SELECT SETVAL('asset.stat_cat_entry_transparency_map_id_seq', COALESCE(MAX(id), 1) ) FROM asset.stat_cat_entry_transparency_map;
SELECT SETVAL('actor.stat_cat_entry_usr_map_id_seq', COALESCE(MAX(id), 1) ) FROM actor.stat_cat_entry_usr_map;
SELECT SETVAL('asset.stat_cat_id_seq', COALESCE(MAX(id), 1) ) FROM asset.stat_cat;
SELECT SETVAL('actor.stat_cat_id_seq', COALESCE(MAX(id), 1) ) FROM actor.stat_cat;
SELECT SETVAL('actor.stat_cat_id_seq', COALESCE(MAX(id), 1) ) FROM actor.stat_cat;
SELECT SETVAL('asset.stat_cat_id_seq', COALESCE(MAX(id), 1) ) FROM asset.stat_cat;
SELECT SETVAL('staging.statcat_stage_row_id_seq', COALESCE(MAX(row_id), 1) ) FROM staging.statcat_stage;
SELECT SETVAL('query.stored_query_id_seq', COALESCE(MAX(id), 1) ) FROM query.stored_query;
SELECT SETVAL('serial.stream_id_seq', COALESCE(MAX(id), 1) ) FROM serial.stream;
SELECT SETVAL('query.subfield_id_seq', COALESCE(MAX(id), 1) ) FROM query.subfield;
SELECT SETVAL('metabib.subject_field_entry_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.subject_field_entry;
SELECT SETVAL('serial.subscription_id_seq', COALESCE(MAX(id), 1) ) FROM serial.subscription;
SELECT SETVAL('serial.subscription_note_id_seq', COALESCE(MAX(id), 1) ) FROM serial.subscription_note;
SELECT SETVAL('serial.supplement_summary_id_seq', COALESCE(MAX(id), 1) ) FROM serial.supplement_summary;
SELECT SETVAL('action.survey_answer_id_seq', COALESCE(MAX(id), 1) ) FROM action.survey_answer;
SELECT SETVAL('action.survey_id_seq', COALESCE(MAX(id), 1) ) FROM action.survey;
SELECT SETVAL('action.survey_question_id_seq', COALESCE(MAX(id), 1) ) FROM action.survey_question;
SELECT SETVAL('action.survey_response_id_seq', COALESCE(MAX(id), 1) ) FROM action.survey_response;
SELECT SETVAL('reporter.template_folder_id_seq', COALESCE(MAX(id), 1) ) FROM reporter.template_folder;
SELECT SETVAL('reporter.template_id_seq', COALESCE(MAX(id), 1) ) FROM reporter.template;
SELECT SETVAL('metabib.title_field_entry_id_seq', COALESCE(MAX(id), 1) ) FROM metabib.title_field_entry;
SELECT SETVAL('actor.toolbar_id_seq', COALESCE(MAX(id), 1) ) FROM actor.toolbar;
SELECT SETVAL('action.transit_copy_id_seq', COALESCE(MAX(id), 1) ) FROM action.transit_copy;
SELECT SETVAL('action.unfulfilled_hold_list_id_seq', COALESCE(MAX(id), 1) ) FROM action.unfulfilled_hold_list;
SELECT SETVAL('asset.uri_call_number_map_id_seq', COALESCE(MAX(id), 1) ) FROM asset.uri_call_number_map;
SELECT SETVAL('asset.uri_id_seq', COALESCE(MAX(id), 1) ) FROM asset.uri;
SELECT SETVAL('container.user_bucket_id_seq', COALESCE(MAX(id), 1) ) FROM container.user_bucket;
SELECT SETVAL('container.user_bucket_item_id_seq', COALESCE(MAX(id), 1) ) FROM container.user_bucket_item;
SELECT SETVAL('container.user_bucket_item_note_id_seq', COALESCE(MAX(id), 1) ) FROM container.user_bucket_item_note;
SELECT SETVAL('container.user_bucket_note_id_seq', COALESCE(MAX(id), 1) ) FROM container.user_bucket_note;
SELECT SETVAL('acq.user_request_id_seq', COALESCE(MAX(id), 1) ) FROM acq.user_request;
SELECT SETVAL('acq.user_request_type_id_seq', COALESCE(MAX(id), 1) ) FROM acq.user_request_type;
SELECT SETVAL('staging.user_stage_row_id_seq', COALESCE(MAX(row_id), 1) ) FROM staging.user_stage;
SELECT SETVAL('actor.usr_activity_id_seq', COALESCE(MAX(id), 1) ) FROM actor.usr_activity;
SELECT SETVAL('config.usr_activity_type_id_seq', COALESCE(MAX(id), 1) ) FROM config.usr_activity_type;
SELECT SETVAL('actor.usr_address_id_seq', COALESCE(MAX(id), 1) ) FROM actor.usr_address;
SELECT SETVAL('permission.usr_grp_map_id_seq', COALESCE(MAX(id), 1) ) FROM permission.usr_grp_map;
SELECT SETVAL('actor.usr_id_seq', COALESCE(MAX(id), 1) ) FROM actor.usr;
SELECT SETVAL('actor.usr_note_id_seq', COALESCE(MAX(id), 1) ) FROM actor.usr_note;
SELECT SETVAL('permission.usr_object_perm_map_id_seq', COALESCE(MAX(id), 1) ) FROM permission.usr_object_perm_map;
SELECT SETVAL('actor.usr_org_unit_opt_in_id_seq', COALESCE(MAX(id), 1) ) FROM actor.usr_org_unit_opt_in;
SELECT SETVAL('actor.usr_password_reset_id_seq', COALESCE(MAX(id), 1) ) FROM actor.usr_password_reset;
SELECT SETVAL('permission.usr_perm_map_id_seq', COALESCE(MAX(id), 1) ) FROM permission.usr_perm_map;
SELECT SETVAL('actor.usr_saved_search_id_seq', COALESCE(MAX(id), 1) ) FROM actor.usr_saved_search;
SELECT SETVAL('actor.usr_setting_id_seq', COALESCE(MAX(id), 1) ) FROM actor.usr_setting;
SELECT SETVAL('actor.usr_standing_penalty_id_seq', COALESCE(MAX(id), 1) ) FROM actor.usr_standing_penalty;
SELECT SETVAL('actor.usr_usrgroup_seq', COALESCE(MAX(usrgroup), 1) ) FROM actor.usr;
SELECT SETVAL('permission.usr_work_ou_map_id_seq', COALESCE(MAX(id), 1) ) FROM permission.usr_work_ou_map;
SELECT SETVAL('config.weight_assoc_id_seq', COALESCE(MAX(id), 1) ) FROM config.weight_assoc;
SELECT SETVAL('actor.workstation_id_seq', COALESCE(MAX(id), 1) ) FROM actor.workstation;
SELECT SETVAL('config.z3950_attr_id_seq', COALESCE(MAX(id), 1) ) FROM config.z3950_attr;
