dump('entering circ/util.js\n');
// vim:noet:sw=4:ts=4:

if (typeof circ == 'undefined') { var circ = {}; }
circ.util = {};

circ.util.EXPORT_OK	= [
	'offline_checkout_columns', 'offline_checkin_columns', 'offline_renew_columns', 'offline_inhouse_use_columns',
	'columns', 'hold_columns', 'checkin_via_barcode', 'std_map_row_to_columns',
	'show_last_few_circs', 'abort_transits', 'transit_columns', 'renew_via_barcode'
];
circ.util.EXPORT_TAGS	= { ':all' : circ.util.EXPORT_OK };

circ.util.abort_transits = function(selection_list) {
	var obj = {};
	JSAN.use('util.error'); obj.error = new util.error();
	JSAN.use('util.network'); obj.network = new util.network();
	JSAN.use('OpenILS.data'); obj.data = new OpenILS.data(); obj.data.init({'via':'stash'});
	JSAN.use('util.functional');
	var copies = util.functional.map_list( selection_list, function(o){return o.copy_id;}).join(', ');
	var msg = document.getElementById('circStrings').getFormattedString('staff.circ.utils.abort_transits.confirm', [copies]);
	var r = obj.error.yns_alert(
		msg,
		document.getElementById('circStrings').getString('staff.circ.utils.abort_transits.title'),
		document.getElementById('circStrings').getString('staff.circ.utils.yes'),
		document.getElementById('circStrings').getString('staff.circ.utils.no'),
		null,
		document.getElementById('circStrings').getString('staff.circ.confirm')
	);
	if (r == 0) {
		try {
			for (var i = 0; i < selection_list.length; i++) {
				var copy_id = selection_list[i].copy_id;
				var robj = obj.network.simple_request('FM_ATC_VOID',[ ses(), { 'copyid' : copy_id } ]);
				if (typeof robj.ilsevent != 'undefined') {
					switch(Number(robj.ilsevent)) {
						case 1225 /* TRANSIT_ABORT_NOT_ALLOWED */ :
							alert(document.getElementById('circString').getFormattedString('staff.circ.utils.abort_transits.not_allowed', [copy_id]) + '\n' + robj.desc);
						break;
						case 1504 /* ACTION_TRANSIT_COPY_NOT_FOUND */ :
							alert(document.getElementById('circString').getString('staff.circ.utils.abort_transits.not_found'));
						break;
						case 5000 /* PERM_FAILURE */ :
						break;
						default:
							throw(robj);
						break;
					}
				}
			}
		} catch(E) {
			obj.error.standard_unexpected_error_alert(document.getElementById('circString').getString('staff.circ.utils.abort_transits.unexpected_error'),E);
		}
	}
};

circ.util.show_copy_details = function(copy_id) {
	var obj = {};
	JSAN.use('util.error'); obj.error = new util.error();
	JSAN.use('util.window'); obj.win = new util.window();
	JSAN.use('util.network'); obj.network = new util.network();
	JSAN.use('OpenILS.data'); obj.data = new OpenILS.data(); obj.data.init({'via':'stash'});

	if (typeof copy_id == 'object' && copy_id != null) copy_id = copy_id.id();

	try {
		var url = xulG.url_prefix( urls.XUL_COPY_DETAILS ); // + '?copy_id=' + copy_id;
		var my_xulG = obj.win.open( url, 'show_copy_details', 'chrome,resizable,modal', { 'copy_id' : copy_id } );

		if (typeof my_xulG.retrieve_these_patrons == 'undefined') return;
		var patrons = my_xulG.retrieve_these_patrons;
		for (var j = 0; j < patrons.length; j++) {
			if (typeof window.xulG == 'object' && typeof window.xulG.new_tab == 'function') {
				try {
					var url = urls.XUL_PATRON_DISPLAY; // + '?id=' + window.escape( patrons[j] );
					window.xulG.new_tab( url, {}, { 'id' : patrons[j] } );
				} catch(E) {
					obj.error.standard_unexpected_error_alert(document.getElementById('circStrings').getString('staff.circ.utils.retrieve_patron.failure'), E);
				}
			}
		}

	} catch(E) {
		obj.error.standard_unexpected_error_alert(document.getElementById('circStrings').getString('staff.circ.utils.retrieve_copy.failure'),E);
	}
};


circ.util.show_last_few_circs = function(selection_list,count) {
	var obj = {};
	JSAN.use('util.error'); obj.error = new util.error();
	JSAN.use('util.window'); obj.win = new util.window();
	JSAN.use('util.network'); obj.network = new util.network();
	JSAN.use('OpenILS.data'); obj.data = new OpenILS.data(); obj.data.init({'via':'stash'});

	if (!count) count = 4;

	for (var i = 0; i < selection_list.length; i++) {
		try {
			if (typeof selection_list[i].copy_id == 'undefined' || selection_list[i].copy_id == null) continue;
			var url = xulG.url_prefix( urls.XUL_CIRC_SUMMARY ); // + '?copy_id=' + selection_list[i].copy_id + '&count=' + count;
			var my_xulG = obj.win.open( url, 'show_last_few_circs', 'chrome,resizable,modal', { 'copy_id' : selection_list[i].copy_id, 'count' : count } );

			if (typeof my_xulG.retrieve_these_patrons == 'undefined') continue;
			var patrons = my_xulG.retrieve_these_patrons;
			for (var j = 0; j < patrons.length; j++) {
				if (typeof window.xulG == 'object' && typeof window.xulG.new_tab == 'function') {
					try {
						var url = urls.XUL_PATRON_DISPLAY; // + '?id=' + window.escape( patrons[j] );
						window.xulG.new_tab( url, {}, { 'id' : patrons[j] } );
					} catch(E) {
						obj.error.standard_unexpected_error_alert(document.getElementById('circStrings').getString('staff.circ.utils.retrieve_patron.failure') ,E);
					}
				}
			}

		} catch(E) {
			obj.error.standard_unexpected_error_alert(document.getElementById('circStrings').getString('staff.circ.utils.retrieve_circs.failure') ,E);
		}
	}
};

circ.util.offline_checkout_columns = function(modify,params) {
	
	var c = [
		{
			'id' : 'timestamp',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.timestamp'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.timestamp; }
		},
		{
			'id' : 'checkout_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.checkout_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.checkout_time; }
		},
		{
			'id' : 'type',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.type'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.type; }
		},
		{
			'id' : 'noncat',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.noncat'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.noncat; }
		},
		{
			'id' : 'noncat_type',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.noncat_type'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.noncat_type; }
		},
		{
			'id' : 'noncat_count',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.count'),
			'sort_type' : 'number',
			'flex' : 1,
			'primary' : false,
			'hidden' : false,
			'render' : function(my) { return my.noncat_count; }
		},
		{
			'id' : 'patron_barcode',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.patron_barcode'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.patron_barcode; }
		},
		{
			'id' : 'barcode',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.item_barcode'),
			'flex' : 2,
			'primary' : true,
			'hidden' : false,
			'render' : function(my) { return my.barcode; }
		},
		{
			'id' : 'due_date',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.due_date'),
			'flex' : 1,
			'primary' : false,
			'hidden' : false,
			'render' : function(my) { return my.due_date; }
		}
	];
	if (modify) for (var i = 0; i < c.length; i++) {
		if (modify[ c[i].id ]) {
			for (var j in modify[ c[i].id ]) {
				c[i][j] = modify[ c[i].id ][j];
			}
		}
	}
	if (params) {
		if (params.just_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < params.just_these.length; i++) {
				var x = util.functional.find_list(c,function(d){return(d.id==params.just_these[i]);});
				new_c.push( function(y){ return y; }( x ) );
			}
			c = new_c;
		}
		if (params.except_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < c.length; i++) {
				var x = util.functional.find_list(params.except_these,function(d){return(d==c[i].id);});
				if (!x) new_c.push(c[i]);
			}
			c = new_c;
		}

	}
	return c.sort( function(a,b) { if (a.label < b.label) return -1; if (a.label > b.label) return 1; return 0; } );
};

circ.util.offline_checkin_columns = function(modify,params) {
	
	var c = [
		{
			'id' : 'timestamp',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.timestamp'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.timestamp; }
		},
		{
			'id' : 'backdate',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.backdate'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.backdate; }
		},
		{
			'id' : 'type',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.type'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.type; }
		},
		{
			'id' : 'barcode',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.item_barcode'),
			'flex' : 2,
			'primary' : true,
			'hidden' : false,
			'render' : function(my) { return my.barcode; }
		}
	];
	if (modify) for (var i = 0; i < c.length; i++) {
		if (modify[ c[i].id ]) {
			for (var j in modify[ c[i].id ]) {
				c[i][j] = modify[ c[i].id ][j];
			}
		}
	}
	if (params) {
		if (params.just_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < params.just_these.length; i++) {
				var x = util.functional.find_list(c,function(d){return(d.id==params.just_these[i]);});
				new_c.push( function(y){ return y; }( x ) );
			}
			c = new_c;
		}
		if (params.except_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < c.length; i++) {
				var x = util.functional.find_list(params.except_these,function(d){return(d==c[i].id);});
				if (!x) new_c.push(c[i]);
			}
			c = new_c;
		}

	}
	return c.sort( function(a,b) { if (a.label < b.label) return -1; if (a.label > b.label) return 1; return 0; } );
};

circ.util.offline_renew_columns = function(modify,params) {
	
	var c = [
		{
			'id' : 'timestamp',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.timestamp'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.timestamp; }
		},
		{
			'id' : 'checkout_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.checkout_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.checkout_time; }
		},
		{
			'id' : 'type',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.type'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.type; }
		},
		{
			'id' : 'patron_barcode',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.patron_barcode'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.patron_barcode; }
		},
		{
			'id' : 'barcode',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.item_barcode'),
			'flex' : 2,
			'primary' : true,
			'hidden' : false,
			'render' : function(my) { return my.barcode; }
		},
		{
			'id' : 'due_date',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.due_date'),
			'flex' : 1,
			'primary' : false,
			'hidden' : false,
			'render' : function(my) { return my.due_date; }
		}
	];
	if (modify) for (var i = 0; i < c.length; i++) {
		if (modify[ c[i].id ]) {
			for (var j in modify[ c[i].id ]) {
				c[i][j] = modify[ c[i].id ][j];
			}
		}
	}
	if (params) {
		if (params.just_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < params.just_these.length; i++) {
				var x = util.functional.find_list(c,function(d){return(d.id==params.just_these[i]);});
				new_c.push( function(y){ return y; }( x ) );
			}
			c = new_c;
		}
		if (params.except_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < c.length; i++) {
				var x = util.functional.find_list(params.except_these,function(d){return(d==c[i].id);});
				if (!x) new_c.push(c[i]);
			}
			c = new_c;
		}

	}
	return c.sort( function(a,b) { if (a.label < b.label) return -1; if (a.label > b.label) return 1; return 0; } );
};

circ.util.offline_inhouse_use_columns = function(modify,params) {
	
	var c = [
		{
			'id' : 'timestamp',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.timestamp'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.timestamp; }
		},
		{
			'id' : 'use_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.use_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.use_time; }
		},
		{
			'id' : 'type',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.type'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.type; }
		},
		{
			'id' : 'count',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.count'),
			'sort_type' : 'number',
			'flex' : 1,
			'primary' : false,
			'hidden' : false,
			'render' : function(my) { return my.count; }
		},
		{
			'id' : 'barcode',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.item_barcode'),
			'flex' : 2,
			'primary' : true,
			'hidden' : false,
			'render' : function(my) { return my.barcode; }
		}
	];
	if (modify) for (var i = 0; i < c.length; i++) {
		if (modify[ c[i].id ]) {
			for (var j in modify[ c[i].id ]) {
				c[i][j] = modify[ c[i].id ][j];
			}
		}
	}
	if (params) {
		if (params.just_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < params.just_these.length; i++) {
				var x = util.functional.find_list(c,function(d){return(d.id==params.just_these[i]);});
				new_c.push( function(y){ return y; }( x ) );
			}
			c = new_c;
		}
		if (params.except_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < c.length; i++) {
				var x = util.functional.find_list(params.except_these,function(d){return(d==c[i].id);});
				if (!x) new_c.push(c[i]);
			}
			c = new_c;
		}

	}
	return c.sort( function(a,b) { if (a.label < b.label) return -1; if (a.label > b.label) return 1; return 0; } );
};

circ.util.columns = function(modify,params) {
	
	JSAN.use('OpenILS.data'); var data = new OpenILS.data(); data.init({'via':'stash'});
	JSAN.use('util.network'); var network = new util.network();
	JSAN.use('util.money');

	var c = [
		{
			'id' : 'acp_id',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_id'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acp.id(); },
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'circ_id',
			'label' : document.getElementById('commonStrings').getString('staff.circ_label_id'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.circ ? my.circ.id() : ( my.acp.circulations() ? my.acp.circulations()[0].id() : ""); },
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'mvr_doc_id',
			'label' : document.getElementById('commonStrings').getString('staff.mvr_label_doc_id'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.doc_id(); },
			'persist' : 'hidden width ordinal'
		},
        {
			'persist' : 'hidden width ordinal',
			'id' : 'service',
			'label' : 'Service',
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.service; }
        },
		{
			'id' : 'barcode',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_barcode'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acp.barcode(); },
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'call_number',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_call_number'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.acp && my.acp.call_number() == -1) {
					return document.getElementById('circStrings').getString('staff.circ.utils.not_cataloged');
				} else if (my.acp && my.acp.call_number() == -2) {
					return document.getElementById('circStrings').getString('staff.circ.utils.retrieving');
				} else {
					if (!my.acn) {
						var x = network.simple_request("FM_ACN_RETRIEVE.authoritative",[ my.acp.call_number() ]);
						if (x.ilsevent) {
							return document.getElementById('circStrings').getString('staff.circ.utils.not_cataloged');
						} else {
							my.acn = x; return x.label();
						}
					} else {
						return my.acn.label();
					}
				}
			},
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'owning_lib',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.owning_lib'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (Number(my.acn.owning_lib())>=0) {
					return data.hash.aou[ my.acn.owning_lib() ].shortname();
				} else {
					return my.acn.owning_lib().shortname();
				}
			},
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'copy_number',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_copy_number'),
			'flex' : 1,
			'sort_type' : 'number',
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acp.copy_number(); },
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'location',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_location'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (Number(my.acp.location())>=0) {
					return data.lookup("acpl", my.acp.location() ).name();
				} else {
					return my.acp.location().name();
				}
			},
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'loan_duration',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_loan_duration'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				switch(Number(my.acp.loan_duration())) {
					case 1:
						return document.getElementById('circStrings').getString('staff.circ.utils.loan_duration.short');
						break;
					case 2:
						return document.getElementById('circStrings').getString('staff.circ.utils.loan_duration.normal');
						break;
					case 3:
						return document.getElementById('circStrings').getString('staff.circ.utils.loan_duration.long');
						break;
				};
			},
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'circ_lib',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_circ_lib'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (Number(my.acp.circ_lib())>=0) {
					return data.hash.aou[ my.acp.circ_lib() ].shortname();
				} else {
					return my.acp.circ_lib().shortname();
				}
			},
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'fine_level',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_fine_level'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				switch(Number(my.acp.fine_level())) {
					case 1:
						return document.getElementById('circStrings').getString('staff.circ.utils.fine_level.low');
						break;
					case 2:
						return document.getElementById('circStrings').getString('staff.circ.utils.fine_level.normal');
						break;
					case 3:
						return document.getElementById('circStrings').getString('staff.circ.utils.fine_level.high');
						break;
				};
			},
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'circulate',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.circulate'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (get_bool( my.acp.circulate() )) {
					return document.getElementById('circStrings').getString('staff.circ.utils.yes');
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.no');
				}
			},
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'deleted',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.deleted'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (get_bool( my.acp.deleted() )) {
					return document.getElementById('circStrings').getString('staff.circ.utils.yes');
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.no');
				}
			},
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'holdable',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.holdable'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (get_bool( my.acp.holdable() )) {
					return document.getElementById('circStrings').getString('staff.circ.utils.yes');
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.no');
				}
			},
			'persist' : 'hidden width ordinal'
		},
		{
			'id' : 'opac_visible',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.opac_visible'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (get_bool( my.acp.opac_visible() )) {
					return document.getElementById('circStrings').getString('staff.circ.utils.yes');
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.no');
				}
			},
			'persist' : 'hidden width ordinal'
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'ref',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.reference'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (get_bool( my.acp.ref() )) {
					return document.getElementById('circStrings').getString('staff.circ.utils.yes');
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.no');
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'deposit',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.deposit'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (get_bool( my.acp.deposit() )) {
					return document.getElementById('circStrings').getString('staff.circ.utils.yes');
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.no');
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'deposit_amount',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_deposit_amount'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.acp.price() == null) {
					return document.getElementById('circStrings').getString('staff.circ.utils.unset');
				} else {
					return util.money.sanitize(my.acp.deposit_amount());
				}
			},
			'sort_type' : 'money'
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'price',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_price'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.acp.price() == null) {
					return document.getElementById('circStrings').getString('staff.circ.utils.unset');
				} else {
					return util.money.sanitize(my.acp.price());
				}
			},
			'sort_type' : 'money'
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'circ_as_type',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_circ_as_type'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acp.circ_as_type(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'circ_modifier',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_circ_modifier'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acp.circ_modifier(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'checkout_lib',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.checkout_lib'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.circ) {
					return data.hash.aou[ my.circ.circ_lib() ].shortname();
				} else {
					if (my.acp.circulations()) {
						return data.hash.aou[ my.acp.circulations()[0].circ_lib() ].shortname();
					} else {
						return "";
					}
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'xact_start_full',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.checkout_timestamp'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.circ) {
					return my.circ.xact_start();
				} else {
					if (my.acp.circulations()) {
						return my.acp.circulations()[0].xact_start();
					}
					else {
						return  "";
					}
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'checkin_time_full',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.checkin_timestamp'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.circ) {
					return my.circ.checkin_time();
				} else {
					if (my.acp.circulations()) {
						return my.acp.circulations()[0].checkin_time();
					} else {
						return "";
					}
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'xact_start',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.xact_start'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.circ) {
					return my.circ.xact_start().substr(0,10);
				} else {
					if (my.acp.circulations()) {
						return my.acp.circulations()[0].xact_start().substr(0,10);
					} else {
						return "";
					}
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'checkin_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.checkin_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.circ) {
					return my.circ.checkin_time().substr(0,10);
				} else {
					if (my.acp.circulations()) {
						return my.acp.circulations()[0].checkin_time().substr(0,10);
					} else {
						return "";
					}
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'xact_finish',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.xact_finish'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.circ.xact_finish(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'due_date',
			'label' : document.getElementById('commonStrings').getString('staff.circ_label_due_date'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.circ) {
					return my.circ.due_date().substr(0,10);
				} else {
					if (my.acp.circulations()) {
						return my.acp.circulations()[0].due_date().substr(0,10);
					} else {
						return "";
					}
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'create_date',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.create_date'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acp.create_date().substr(0,10); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'edit_date',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.edit_date'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acp.edit_date().substr(0,10); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'title',
			'label' : document.getElementById('commonStrings').getString('staff.mvr_label_title'),
			'flex' : 2,
			'sort_type' : 'title',
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				try {  return my.mvr.title(); }
				catch(E) { return my.acp.dummy_title(); }
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'author',
			'label' : document.getElementById('commonStrings').getString('staff.mvr_label_author'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				try { return my.mvr.author(); }
				catch(E) { return my.acp.dummy_author(); }
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'edition',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.edition'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.edition(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'isbn',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.isbn'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.isbn(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'pubdate',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.pubdate'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.pubdate(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'publisher',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.publisher'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.publisher(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'tcn',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.tcn'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.tcn(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'renewal_remaining',
			'label' : document.getElementById('commonStrings').getString('staff.circ_label_renewal_remaining'),
			'flex' : 0,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.circ) {
					return my.circ.renewal_remaining();
				} else {
					if (my.acp.circulations()) {
						return my.acp.circulations()[0].renewal_remaining();
					} else {
						return "";
					}
				}
			},
			'sort_type' : 'number'
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'stop_fines',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.stop_fines'),
			'flex' : 0,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.circ) {
					return my.circ.stop_fines();
				} else {
					if (my.acp.circulations()) {
						return my.acp.circulations()[0].stop_fines();
					} else {
						return "";
					}
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'stop_fines_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.stop_fines_time'),
			'flex' : 0,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.circ) {
					return my.circ.stop_fines_time();
				} else {
					if (my.acp.circulations()) {
						return my.acp.circulations()[0].stop_fines_time();
					} else {
						return "";
					}
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'status',
			'label' : document.getElementById('commonStrings').getString('staff.acp_label_status'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (Number(my.acp.status())>=0) {
					return data.hash.ccs[ my.acp.status() ].name();
				} else {
					return my.acp.status().name();
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'route_to',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.route_to'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.route_to.toString(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'message',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.message'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.message.toString(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'uses',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.uses'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.uses; },
			'sort_type' : 'number'
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'alert_message',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.alert_message'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acp.alert_message(); }
		}
	];
	for (var i = 0; i < c.length; i++) {
		if (modify[ c[i].id ]) {
			for (var j in modify[ c[i].id ]) {
				c[i][j] = modify[ c[i].id ][j];
			}
		}
	}
	if (params) {
		if (params.just_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < params.just_these.length; i++) {
				var x = util.functional.find_list(c,function(d){return(d.id==params.just_these[i]);});
				new_c.push( function(y){ return y; }( x ) );
			}
			c = new_c;
		}
		if (params.except_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < c.length; i++) {
				var x = util.functional.find_list(params.except_these,function(d){return(d==c[i].id);});
				if (!x) new_c.push(c[i]);
			}
			c = new_c;
		}
	}
	return c.sort( function(a,b) { if (a.label < b.label) return -1; if (a.label > b.label) return 1; return 0; } );
};

circ.util.transit_columns = function(modify,params) {
	
	JSAN.use('OpenILS.data'); var data = new OpenILS.data(); data.init({'via':'stash'});

	var c = [
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_item_barcode',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.barcode'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acp.barcode(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_item_title',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.title'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				try { return my.mvr.title(); }
				catch(E) { return my.acp.dummy_title(); }
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_item_author',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.author'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				try { return my.mvr.author(); }
				catch(E) { return my.acp.dummy_author(); }
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_item_callnumber',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.callnumber'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acn.label(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_id',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.transit_id'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.atc.id(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_source',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.transit_source'),
			'flex' : 1,
			'primary' : false,
			'hidden' : false,
			'render' : function(my) {
				if (typeof my.atc.source() == "object") {
					return my.atc.source().shortname();
				} else {
					return data.hash.aou[ my.atc.source() ].shortname();
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_source_send_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.transit_source_send_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : false,
			'render' : function(my) { return my.atc.source_send_time(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_dest_lib',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.transit_dest'),
			'flex' : 1,
			'primary' : false,
			'hidden' : false,
			'render' : function(my) {
				if (typeof my.atc.dest() == "object") {
					return my.atc.dest().shortname();
				} else {
					return data.hash.aou[ my.atc.dest() ].shortname();
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_dest_recv_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.transit_dest_recv_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : false,
			'render' : function(my) { return my.atc.dest_recv_time(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_target_copy',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.transit_target_copy'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.atc.target_copy(); }
		},
	];
	for (var i = 0; i < c.length; i++) {
		if (modify[ c[i].id ]) {
			for (var j in modify[ c[i].id ]) {
				c[i][j] = modify[ c[i].id ][j];
			}
		}
	}
	if (params) {
		if (params.just_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < params.just_these.length; i++) {
				var x = util.functional.find_list(c,function(d){return(d.id==params.just_these[i]);});
				new_c.push( function(y){ return y; }( x ) );
			}
			c = new_c;
		}
		if (params.except_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < c.length; i++) {
				var x = util.functional.find_list(params.except_these,function(d){return(d==c[i].id);});
				if (!x) new_c.push(c[i]);
			}
			c = new_c;
		}

	}
	return c.sort( function(a,b) { if (a.label < b.label) return -1; if (a.label > b.label) return 1; return 0; } );
};

circ.util.hold_columns = function(modify,params) {
	
	JSAN.use('OpenILS.data'); var data = new OpenILS.data(); data.init({'via':'stash'});

	var c = [
		{
			'persist' : 'hidden width ordinal',
			'id' : 'request_lib',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.request_lib'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (Number(my.ahr.request_lib())>=0) {
					return data.hash.aou[ my.ahr.request_lib() ].name();
				} else {
					return my.ahr.request_lib().name();
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'request_lib_shortname',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.request_lib_shortname'),
			'flex' : 0,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (Number(my.ahr.request_lib())>=0) {
					return data.hash.aou[ my.ahr.request_lib() ].shortname();
				} else {
					return my.ahr.request_lib().shortname();
				}
			}
		},

		{
			'persist' : 'hidden width ordinal',
			'id' : 'request_timestamp',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.request_timestamp'),
			'flex' : 0,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.request_time().toString(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'request_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.request_time'),
			'flex' : 0,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.request_time().toString().substr(0,10); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'available_timestamp',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.available_timestamp'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.ahr.transit() && my.ahr.transit().dest_recv_time()) {
					return my.ahr.transit().dest_recv_time().toString();
				}
				if (my.ahr.capture_time()) {
					return my.ahr.capture_time().toString();
				}
				return "";
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'available_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.available_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : false,
			'render' : function(my) {
				if (my.ahr.transit() && my.ahr.transit().dest_recv_time()) {
					return my.ahr.transit().dest_recv_time().toString().substr(0,10);
				}
				if (my.ahr.capture_time()) {
					return my.ahr.capture_time().toString().substr(0,10);
				}
				return "";
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'capture_timestamp',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.capture_timestamp'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.capture_time() ? my.ahr.capture_time().toString() : ""; }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'capture_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.capture_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.capture_time() ? my.ahr.capture_time().toString().substr(0,10) : ""; }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'status',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_status_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : false,
			'render' : function(my) {
				switch (Number(my.status)) {
					case 1:
						return document.getElementById('circStrings').getString('staff.circ.utils.hold_status.1');
						break;
					case 2:
						return document.getElementById('circStrings').getString('staff.circ.utils.hold_status.2');
						break;
					case 3:
						return document.getElementById('circStrings').getString('staff.circ.utils.hold_status.3');
						break;
					case 4:
						return document.getElementById('circStrings').getString('staff.circ.utils.hold_status.4');
						break;
					default:
						return my.status;
						break;
				};
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'hold_type',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_hold_type_label'),
			'flex' : 0,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.hold_type(); }
		},
        {
			'persist' : 'hidden width ordinal',
			'id' : 'frozen',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.active'),
			'flex' : 0,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (!get_bool( my.ahr.frozen() )) {
					return document.getElementById('circStrings').getString('staff.circ.utils.yes');
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.no');
				}
			}
        },
        {
			'persist' : 'hidden width ordinal',
			'id' : 'thaw_date',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.thaw_date'),
			'flex' : 0,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.ahr.thaw_date() == null) {
					return document.getElementById('circStrings').getString('staff.circ.utils.thaw_date.none');
				} else {
					return my.ahr.thaw_date().substr(0,10);
				}
			}
        },
		{
			'persist' : 'hidden width ordinal',
			'id' : 'pickup_lib',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.pickup_lib'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (Number(my.ahr.pickup_lib())>=0) {
					return data.hash.aou[ my.ahr.pickup_lib() ].name();
				} else {
					return my.ahr.pickup_lib().name();
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'pickup_lib_shortname',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_pickup_lib_label'),
			'flex' : 0,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (Number(my.ahr.pickup_lib())>=0) {
					return data.hash.aou[ my.ahr.pickup_lib() ].shortname();
				} else {
					return my.ahr.pickup_lib().shortname();
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'current_copy',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_current_copy_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.acp) {
					return my.acp.barcode();
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.current_copy.none');
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'current_copy_location', 
			'label' : document.getElementById('commonStrings').getString('staff.ahr_current_copy_location_label'),
            'flex' : 1,
			'primary' : false, 
            'hidden' : true, 
            'render' : function(my) { 
                if (!my.acp) { return ""; } else { if (Number(my.acp.location())>=0) return data.lookup("acpl", my.acp.location() ).name(); else return my.acp.location().name(); } 
            }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'email_notify',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_email_notify_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (get_bool(my.ahr.email_notify())) {
					return document.getElementById('circStrings').getString('staff.circ.utils.yes');
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.no');
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'expire_time',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_expire_time_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.expire_time(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'fulfillment_time',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_fulfillment_time_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.fulfillment_time(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'holdable_formats',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_holdable_formats_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.holdable_formats(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'id',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_id_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.id(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'phone_notify',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_phone_notify_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.phone_notify(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'prev_check_time',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_prev_check_time_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.prev_check_time(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'requestor',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_requestor_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.requestor(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'selection_depth',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_selection_depth_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.selection_depth(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'target',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_target_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.target(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'usr',
			'label' : document.getElementById('commonStrings').getString('staff.ahr_usr_label'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.usr(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'title',
			'label' : document.getElementById('commonStrings').getString('staff.mvr_label_title'),
			'flex' : 1,
			'sort_type' : 'title',
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.mvr) {
					return my.mvr.title();
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.title.none');
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'author',
			'label' : document.getElementById('commonStrings').getString('staff.mvr_label_author'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.mvr) {
					return my.mvr.author();
				} else {
					return document.getElementById('circStrings').getString('staff.circ.utils.author.none');
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'edition',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.edition'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.edition(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'isbn',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.isbn'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.isbn(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'pubdate',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.pubdate'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.pubdate(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'publisher',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.publisher'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.publisher(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'tcn',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.tcn'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.mvr.tcn(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'notify_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.notify_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.notify_time(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'notify_count',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.notify_count'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.notify_count(); }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_source',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.transit_source'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) {
				if (my.ahr.transit()) {
					return data.hash.aou[ my.ahr.transit().source() ].shortname();
				} else {
					return "";
				}
			}
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_source_send_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.transit_source_send_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.transit() ?  my.ahr.transit().source_send_time() : ""; }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_dest_lib',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.transit_dest'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.transit() ?  data.hash.aou[ my.ahr.transit().dest() ].shortname() : ""; }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'transit_dest_recv_time',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.transit_dest_recv_time'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.ahr.transit() ?  my.ahr.transit().dest_recv_time() : ""; }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'patron_barcode',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.offline.patron_barcode'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.patron_barcode ? my.patron_barcode : ""; }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'patron_family_name',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.patron_family_name'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.patron_family_name ? my.patron_family_name : ""; }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'patron_first_given_name',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.patron_first_given_name'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.patron_first_given_name ? my.patron_first_given_name : ""; }
		},
		{
			'persist' : 'hidden width ordinal',
			'id' : 'callnumber',
			'label' : document.getElementById('circStrings').getString('staff.circ.utils.callnumber'),
			'flex' : 1,
			'primary' : false,
			'hidden' : true,
			'render' : function(my) { return my.acn.label(); }
		},
	];
	for (var i = 0; i < c.length; i++) {
		if (modify[ c[i].id ]) {
			for (var j in modify[ c[i].id ]) {
				c[i][j] = modify[ c[i].id ][j];
			}
		}
	}
	if (params) {
		if (params.just_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < params.just_these.length; i++) {
				var x = util.functional.find_list(c,function(d){return(d.id==params.just_these[i]);});
				new_c.push( function(y){ return y; }( x ) );
			}
			c = new_c;
		}
		if (params.except_these) {
			JSAN.use('util.functional');
			var new_c = [];
			for (var i = 0; i < c.length; i++) {
				var x = util.functional.find_list(params.except_these,function(d){return(d==c[i].id);});
				if (!x) new_c.push(c[i]);
			}
			c = new_c;
		}

	}
	return c.sort( function(a,b) { if (a.label < b.label) return -1; if (a.label > b.label) return 1; return 0; } );
};
/*
circ.util.std_map_row_to_column = function(error_value) {
	return function(row,col) {
		// row contains { 'my' : { 'acp' : {}, 'circ' : {}, 'mvr' : {} } }
		// col contains one of the objects listed above in columns
		
		// mimicking some of the obj in circ.checkin and circ.checkout where map_row_to_column is usually defined
		var obj = {};
		JSAN.use('util.error'); obj.error = new util.error();
		JSAN.use('OpenILS.data'); obj.data = new OpenILS.data(); obj.data.init({'via':'stash'});
		JSAN.use('util.network'); obj.network = new util.network();
		JSAN.use('util.money');

		var my = row.my;
		var value;
		try {
			value = eval( col.render );
		} catch(E) {
			obj.error.sdump('D_WARN','map_row_to_column: ' + E);
			if (error_value) value = error_value; else value = '   ';
		}
		return value;
	}
};
*/
circ.util.std_map_row_to_columns = function(error_value) {
	return function(row,cols) {
		// row contains { 'my' : { 'acp' : {}, 'circ' : {}, 'mvr' : {} } }
		// cols contains all of the objects listed above in columns
		
		var obj = {};
		JSAN.use('util.error'); obj.error = new util.error();
		JSAN.use('OpenILS.data'); obj.data = new OpenILS.data(); obj.data.init({'via':'stash'});
		JSAN.use('util.network'); obj.network = new util.network();
		JSAN.use('util.money');

		var my = row.my;
		var values = [];
		var cmd = '';
		try {
			for (var i = 0; i < cols.length; i++) {
				switch (typeof cols[i].render) {
					case 'function': try { values[i] = cols[i].render(my); } catch(E) { values[i] = error_value; obj.error.sdump('D_COLUMN_RENDER_ERROR',E); } break;
					case 'string' : cmd += 'try { ' + cols[i].render + '; values['+i+'] = v; } catch(E) { values['+i+'] = error_value; }'; break;
					default: cmd += 'values['+i+'] = "??? '+(typeof cols[i].render)+'"; ';
				}
			}
			if (cmd) eval( cmd );
		} catch(E) {
			obj.error.sdump('D_WARN','map_row_to_column: ' + E);
			if (error_value) { value = error_value; } else { value = '   ' };
		}
		return values;
	}
};

circ.util.checkin_via_barcode = function(session,params,backdate,auto_print,async) {
	try {
		JSAN.use('util.error'); var error = new util.error();
		JSAN.use('util.network'); var network = new util.network();
		JSAN.use('OpenILS.data'); var data = new OpenILS.data(); data.init({'via':'stash'});
		JSAN.use('util.date');

		if (backdate && (backdate == util.date.formatted_date(new Date(),'%Y-%m-%d')) ) backdate = null;

		//var params = { 'barcode' : barcode };
		if (backdate) params.backdate = util.date.formatted_date(backdate + ' 00:00:00','%{iso8601}');

		if (typeof async == 'object') {
			try { async.disable_textbox(); }
			catch(E) { error.sdump('D_ERROR','async.disable_textbox() = ' + E); };
		}
		var check = network.request(
			api.CHECKIN_VIA_BARCODE.app,
			api.CHECKIN_VIA_BARCODE.method,
			[ session, params ],
			async ? function(req) {
				try {
					var check = req.getResultObject();
					var r = circ.util.checkin_via_barcode2(session,params,backdate,auto_print,check);
					if (typeof async == 'object') {
						try { async.checkin_result(r); }
						catch(E) { error.sdump('D_ERROR','async.checkin_result() = ' + E); };
					}
				} catch(E) {
					JSAN.use('util.error'); var error = new util.error();
					error.standard_unexpected_error_alert(document.getElementById('circStrings').getFormattedMessage('staff.circ.checkin.error', ['1']), E);
					if (typeof async == 'object') {
						try { async.enable_textbox(); }
						catch(E) { error.sdump('D_ERROR','async.disable_textbox() = ' + E); };
					}
					return null;
				}
			} : null,
			{
				'title' : document.getElementById('circStrings').getString('staff.circ.utils.checkin.override'),
				'overridable_events' : [
					1203 /* COPY_BAD_STATUS */,
					1213 /* PATRON_BARRED */,
					1217 /* PATRON_INACTIVE */,
					1224 /* PATRON_ACCOUNT_EXPIRED */,
					7009 /* CIRC_CLAIMS_RETURNED */,
					7010 /* COPY_ALERT_MESSAGE */,
					7011 /* COPY_STATUS_LOST */,
					7012 /* COPY_STATUS_MISSING */,
					7013 /* PATRON_EXCEEDS_FINES */,
				],
				'text' : {
					'1203' : function(r) {
						//return data.hash.ccs[ r.payload.status() ].name();
						return r.payload.status().name();
					},
					'7010' : function(r) {
						return r.payload;
					}
				}
			}
		);
		if (!async) {
			return circ.util.checkin_via_barcode2(session,params,backdate,auto_print,check);
		}


	} catch(E) {
		JSAN.use('util.error'); var error = new util.error();
		error.standard_unexpected_error_alert(document.getElementById('circStrings').getFormattedMessage('staff.circ.checkin.error', ['2']), E);
		if (typeof async == 'object') {
			try { async.enable_textbox(); } catch(E) { error.sdump('D_ERROR','async.disable_textbox() = ' + E); };
		}
		return null;
	}
};

circ.util.checkin_via_barcode2 = function(session,params,backdate,auto_print,check) {
	try {
		JSAN.use('util.error'); var error = new util.error();
		JSAN.use('util.network'); var network = new util.network();
		JSAN.use('OpenILS.data'); var data = new OpenILS.data(); data.init({'via':'stash'});
		JSAN.use('util.date');

		error.sdump('D_DEBUG','check = ' + error.pretty_print( js2JSON( check ) ) );

		check.message = check.textcode;

		if (check.payload && check.payload.copy) { check.copy = check.payload.copy; }
		if (check.payload && check.payload.record) { check.record = check.payload.record; }
		if (check.payload && check.payload.circ) { check.circ = check.payload.circ; }

		if (!check.route_to) { check.route_to = '   '; }

		if (document.getElementById('no_change_label')) {
			document.getElementById('no_change_label').setAttribute('value','');
			document.getElementById('no_change_label').setAttribute('hidden','true');
		}

		if (check.circ) {
			network.simple_request('FM_MBTS_RETRIEVE.authoritative',[ses(),check.circ.id()], function(req) {
				JSAN.use('util.money');
				var bill = req.getResultObject();
				if (Number(bill.balance_owed()) == 0) { return; }
				if (document.getElementById('no_change_label')) {
					var m = document.getElementById('no_change_label').getAttribute('value');
					document.getElementById('no_change_label').setAttribute('value', m + document.getElementById('circStrings').getFormattedString('staff.circ.utils.billable.amount', [params.barcode, util.money.sanitize(bill.balance_owed())]) + '  ');
					document.getElementById('no_change_label').setAttribute('hidden','false');
				}
			});
		}

		var msg = '';

		if (check.payload && check.payload.cancelled_hold_transit) {
			msg += document.getElementById('circStrings').getString('staff.circ.utils.transit_hold_cancelled');
			msg += '\n\n';
		}

		/* SUCCESS  /  NO_CHANGE  /  ITEM_NOT_CATALOGED */
		if (check.ilsevent == 0 || check.ilsevent == 3 || check.ilsevent == 1202) {
			try { check.route_to = data.lookup('acpl', check.copy.location() ).name(); }
			catch(E) {
				msg += document.getElementById('commonStrings').getString('common.error');
				msg += '\nFIXME: ' + E + '\n';
			}
			if (check.ilsevent == 3 /* NO_CHANGE */) {
				//msg = 'This item is already checked in.\n';
				if (document.getElementById('no_change_label')) {
					var m = document.getElementById('no_change_label').getAttribute('value');
					document.getElementById('no_change_label').setAttribute('value', m + document.getElementById('circStrings').getFormattedString('staff.circ.utils.item_checked_in', [params.barcode]) + '  ');
					document.getElementById('no_change_label').setAttribute('hidden','false');
				}
			}
			if (check.ilsevent == 1202 /* ITEM_NOT_CATALOGED */ && check.copy.status() != 11) {
				var copy_status = (data.hash.ccs[ check.copy.status() ] ? data.hash.ccs[ check.copy.status() ].name() : check.copy.status().name() );
				msg = document.getElementById('commonStrings').getString('common.error');
				msg += '\nFIXME --';
				msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.item_not_cataloged', [copy_status]);
				msg + '\n';
			}
			switch(Number(check.copy.status())) {
				case 0: /* AVAILABLE */
				case 7: /* RESHELVING */
					if (msg) {
						msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.route_to.msg', [check.route_to]);
						msg += '\n';
					}
				break;
				case 8: /* ON HOLDS SHELF */
					check.route_to = 'HOLDS SHELF';
					if (check.payload.hold) {
						if (check.payload.hold.pickup_lib() != data.list.au[0].ws_ou()) {
							msg += document.getElementById('commonStrings').getString('common.error');
							msg += '\nFIXME: ';
							msg += document.getElementById('circStrings').getString('staff.circ.utils.route_item_error');
							msg += '\n';
						} else {
							msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.route_to.msg', [check.route_to]);
							msg += '.\n';
						}
					} else {
						msg += document.getElementById('commonStrings').getString('common.error');
						msg += '\nFIXME: ';
						msg += document.getElementById('circStrings').getString('staff.circ.utils.route_item_status_error');
						msg += '\n';
					}
					JSAN.use('util.date');
					if (check.payload.hold) {
						JSAN.use('patron.util');
						msg += '\n';
						msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.barcode', [check.payload.copy.barcode()]);
						msg += '\n';
						var payload_title  = (check.payload.record ? check.payload.record.title() : check.payload.copy.dummy_title() );
						msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.title', [payload_title]);
						msg += '\n';
						var au_obj = patron.util.retrieve_fleshed_au_via_id( session, check.payload.hold.usr() );
						msg += '\n';
						msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.patron',  [au_obj.family_name(), au_obj.first_given_name(), au_obj.second_given_name()]);
						msg += '\n';
						msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.barcode', [au_obj.card().barcode()]);
						msg += '\n';
						if (check.payload.hold.phone_notify()) {
							msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.phone_notify', [check.payload.hold.phone_notify()]);
							msg += '\n';
						}
						if (check.payload.hold.email_notify()) {
							var payload_email = au_obj.email() ? au_obj.email() : '';
							msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.email_notify', [payload_email]);
							msg += '\n';
						}
						msg += '\n';
						msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.request_date', [util.date.formatted_date(check.payload.hold.request_time(),'%F')]);
						msg += '\n';
					}
					var rv = 0;
					msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.slip_date', [util.date.formatted_date(new Date(),'%F')]);
					msg += '\n';
					if (!auto_print) {
						rv = error.yns_alert_formatted(
							msg,
							document.getElementById('circStrings').getString('staff.circ.utils.hold_slip'),
							document.getElementById('circStrings').getString('staff.circ.utils.hold_slip.print.yes'),
							document.getElementById('circStrings').getString('staff.circ.utils.hold_slip.print.no'),
							null,
							document.getElementById('circStrings').getString('staff.circ.confirm.msg'),
							'/xul/server/skin/media/images/turtle.gif'
						);
					}
					if (rv == 0) {
						try {
							JSAN.use('util.print'); var print = new util.print();
							msg = msg.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\n/g,'<br/>');
							print.simple( msg , { 'no_prompt' : true, 'content_type' : 'text/html' } );
						} catch(E) {
							var err_msg = document.getElementById('commonStrings').getString('common.error');
							err_msg += '\nFIXME: ' + E + '\n';
							dump(err_msg);
							alert(err_msg);
						}
					}
					msg = '';
					if (document.getElementById('no_change_label')) {
						var m = document.getElementById('no_change_label').getAttribute('value');
						m += document.getElementById('circStrings').getFormattedString('staff.circ.utils.capture', [params.barcode]);
						document.getElementById('no_change_label').setAttribute('value', m);
						document.getElementById('no_change_label').setAttribute('hidden','false');
					}
				break;
				case 6: /* IN TRANSIT */
					check.route_to = 'TRANSIT SHELF??';
					msg += document.getElementById('commonStrings').getString('common.error');
					msg += "\nFIXME -- I didn't think we could get here.\n";
				break;
				case 11: /* CATALOGING */
					check.route_to = 'CATALOGING';
					if (document.getElementById('do_not_alert_on_precat')) {
						var x = document.getElementById('do_not_alert_on_precat');
						if (! x.checked) {
							msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.route_to.msg', [check.route_to]);
						}
					} else {
						msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.route_to.msg', [check.route_to]);
					}
					if (document.getElementById('no_change_label')) {
						var m = document.getElementById('no_change_label').getAttribute('value');
						var needs_cat = document.getElementById('circStrings').getFormattedString('staff.circ.utils.needs_cataloging', [params.barcode]);
						document.getElementById('no_change_label').setAttribute('value', m + needs_cat + '  ');
						document.getElementById('no_change_label').setAttribute('hidden','false');
					}
				break;
				default:
					msg += document.getElementById('commonStrings').getString('common.error');
					var copy_status = data.hash.ccs[check.copy.status()] ? data.hash.ccs[check.copy.status()].name() : check.copy.status().name();
					msg += '\n';
					msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.copy_status.error', [copy_status]);
					msg += '\n';
					msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.route_to.msg', [check.route_to]);
				break;
			}
			if (msg) {
				error.yns_alert(
					msg,
					document.getElementById('circStrings').getString('staff.circ.alert'),
					null,
					document.getElementById('circStrings').getString('staff.circ.utils.msg.ok'),
					null,
					document.getElementById('circStrings').getString('staff.circ.confirm.msg')
				);
			}
		} else /* ROUTE_ITEM */ if (check.ilsevent == 7000) {

			var lib = data.hash.aou[ check.org ];
			check.route_to = lib.shortname();
			msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.route_to.destination', [check.route_to]);
			msg += '\n\n';
			msg += lib.name();
			msg += '\n';
			try {
				if (lib.holds_address() ) {
					var a = network.simple_request('FM_AOA_RETRIEVE',[ lib.holds_address() ]);
					if (typeof a.ilsevent != 'undefined') throw(a);
					if (a.street1()) msg += a.street1() + '\n';
					if (a.street2()) msg += a.street2() + '\n';
					msg += (a.city() ? a.city() + ', ' : '') + (a.state() ? a.state() + ' ' : '') + (a.post_code() ? a.post_code() : '') + '\n';
				} else {
					msg += document.getElementById('circStrings').getString('staff.circ.utils.route_to.no_address');
					msg += '\n';
				}
			} catch(E) {
				msg += document.getElementById('circStrings').getString('staff.circ.utils.route_to.no_address.error');
				msg += '\n';
				error.standard_unexpected_error_alert(document.getElementById('circStrings').getString('staff.circ.utils.route_to.no_address.error'), E);
			}
			msg += '\n';
			msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.barcode', [check.payload.copy.barcode()]);
			msg += '\n';
			var payload_title  = (check.payload.record ? check.payload.record.title() : check.payload.copy.dummy_title() );
			msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.title', [payload_title]);
			msg += '\n';
			var payload_author = (check.payload.record ? check.payload.record.author() :check.payload.copy.dummy_author());
			msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.author', [payload_author]);
			msg += '\n';
			JSAN.use('util.date');
			if (check.payload.hold) {
				JSAN.use('patron.util');
				var au_obj = patron.util.retrieve_fleshed_au_via_id( session, check.payload.hold.usr() );
				msg += '\n';
				document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.patron', [au_obj.family_name(), au_obj.first_given_name(), au_obj.second_given_name()]);
				msg += '\n';
				msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.barcode', [au_obj.card().barcode()]);
				msg += '\n';
				if (check.payload.hold.phone_notify()) {
					msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.phone_notify', [check.payload.hold.phone_notify()]);
					msg += '\n';
				}
				if (check.payload.hold.email_notify()) {
					var payload_email = au_obj.email() ? au_obj.email() : '';
					msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.email_notify', [payload_email]);
					msg += '\n';
				}
				msg += '\n';
				msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.request_date', [util.date.formatted_date(check.payload.hold.request_time(),'%F')]);
				msg += '\n';
			}
			var rv = 0;
			msg += document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.hold.slip_date', [util.date.formatted_date(new Date(),'%F')]);
			if (!auto_print) {
				rv = error.yns_alert_formatted(
					msg,
					document.getElementById('circStrings').getString('staff.circ.utils.hold_slip'),
					document.getElementById('circStrings').getString('staff.circ.utils.hold_slip.print.yes'),
					document.getElementById('circStrings').getString('staff.circ.utils.hold_slip.print.no'),
					null,
					document.getElementById('circStrings').getString('staff.circ.confirm.msg'),
					'/xul/server/skin/media/images/turtle.gif'
				);
			}

			if (rv == 0) {
				try {
					JSAN.use('util.print'); var print = new util.print();
					//print.simple( msg, { 'no_prompt' : true, 'content_type' : 'text/plain' } );
					msg = msg.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/\n/g,'<br/>');
					print.simple( msg , { 'no_prompt' : true, 'content_type' : 'text/html' } );
				} catch(E) {
					var err_msg = document.getElementById('commonStrings').getString('common.error');
					err_msg += '\nFIXME: ' + E + '\n';
					dump(err_msg);
					alert(err_msg);
				}
			}
			if (document.getElementById('no_change_label')) {
				var m = document.getElementById('no_change_label').getAttribute('value');
				var trans_msg = document.getElementById('circStrings').getFormattedString('staff.circ.utils.payload.in_transit', [params.barcode]);
				document.getElementById('no_change_label').setAttribute('value', m + trans_msg + '  ');
				document.getElementById('no_change_label').setAttribute('hidden','false');
			}

		} else /* ASSET_COPY_NOT_FOUND */ if (check.ilsevent == 1502) {

			check.route_to = 'CATALOGING';
			var mis_scan_msg = document.getElementById('circStrings').getFormattedString('staff.circ.copy_status.status.copy_not_found', [params.barcode]);
			error.yns_alert(
				mis_scan_msg,
				document.getElementById('circStrings').getString('staff.circ.alert'),
				null,
				document.getElementById('circStrings').getString('staff.circ.utils.msg.ok'),
				null,
				document.getElementById('circStrings').getString('staff.circ.confirm.msg')
			);
			if (document.getElementById('no_change_label')) {
				var m = document.getElementById('no_change_label').getAttribute('value');
				document.getElementById('no_change_label').setAttribute('value',m + mis_scan_msg + '  ');
				document.getElementById('no_change_label').setAttribute('hidden','false');
			}

		} else /* NETWORK TIMEOUT */ if (check.ilsevent == -1) {
			error.standard_network_error_alert(document.getElementById('circStrings').getString('staff.circ.checkin.suggest_offline'));
		} else {

			switch (Number(check.ilsevent)) {
				case 1203 /* COPY_BAD_STATUS */ :
				case 1213 /* PATRON_BARRED */ :
				case 1217 /* PATRON_INACTIVE */ :
				case 1224 /* PATRON_ACCOUNT_EXPIRED */ :
				case 7009 /* CIRC_CLAIMS_RETURNED */ :
				case 7010 /* COPY_ALERT_MESSAGE */ :
				case 7011 /* COPY_STATUS_LOST */ :
				case 7012 /* COPY_STATUS_MISSING */ :
				case 7013 /* PATRON_EXCEEDS_FINES */ :
					return null; /* handled */
				break;
			}

			throw(check);

		}

		return check;
	} catch(E) {
		JSAN.use('util.error'); var error = new util.error();
		error.standard_unexpected_error_alert(document.getElementById('circStrings').getFormattedMessage('staff.circ.checkin.error', ['3']), E);
		return null;
	}
};

circ.util.renew_via_barcode = function ( barcode, patron_id, async ) {
	try {
		var obj = {};
		JSAN.use('util.network'); obj.network = new util.network();
		JSAN.use('OpenILS.data'); obj.data = new OpenILS.data(); obj.data.stash_retrieve();

		var params = { barcode: barcode };
		if (patron_id) params.patron = patron_id;

		function renew_callback(req) {
			try {
				var renew = req.getResultObject();
				if (typeof renew.ilsevent != 'undefined') renew = [ renew ];
				for (var j = 0; j < renew.length; j++) {
					switch(Number(renew[j].ilsevent)) {
						case 0 /* SUCCESS */ : break;
						case 5000 /* PERM_FAILURE */: break;
						case 1212 /* PATRON_EXCEEDS_OVERDUE_COUNT */ : break;
						case 1213 /* PATRON_BARRED */ : break;
						case 1215 /* CIRC_EXCEEDS_COPY_RANGE */ : break;
						case 1224 /* PATRON_ACCOUNT_EXPIRED */ : break;
						case 1500 /* ACTION_CIRCULATION_NOT_FOUND */ : break;
						case 7002 /* PATRON_EXCEEDS_CHECKOUT_COUNT */ : break;
						case 7003 /* COPY_CIRC_NOT_ALLOWED */ : break;
						case 7004 /* COPY_NOT_AVAILABLE */ : break;
						case 7006 /* COPY_IS_REFERENCE */ : break;
						case 7007 /* COPY_NEEDED_FOR_HOLD */ : break;
						case 7008 /* MAX_RENEWALS_REACHED */ : break;
						case 7009 /* CIRC_CLAIMS_RETURNED */ : break;
						case 7010 /* COPY_ALERT_MESSAGE */ : break;
						case 7013 /* PATRON_EXCEEDS_FINES */ : break;
						default:
							throw(renew);
						break;
					}
				}
				if (typeof async == 'function') async(renew);
				return renew;
			} catch(E) {
				JSAN.use('util.error'); var error = new util.error();
				error.standard_unexpected_error_alert(document.getElementById('circStrings').getFormattedMessage('staff.circ.checkin.renew_failed.error', [barcode]), E);
				return null;
			}
		}

		var renew = obj.network.simple_request(
			'CHECKOUT_RENEW',
			[ ses(), params ],
			async ? renew_callback : null,
			{
				'title' : document.getElementById('circStrings').getMessage('staff.circ.checkin.renew_failed.override'),
				'overridable_events' : [
					1212 /* PATRON_EXCEEDS_OVERDUE_COUNT */,
					1213 /* PATRON_BARRED */,
					1215 /* CIRC_EXCEEDS_COPY_RANGE */,
					7002 /* PATRON_EXCEEDS_CHECKOUT_COUNT */,
					7003 /* COPY_CIRC_NOT_ALLOWED */,
					7004 /* COPY_NOT_AVAILABLE */,
					7006 /* COPY_IS_REFERENCE */,
					7007 /* COPY_NEEDED_FOR_HOLD */,
					7008 /* MAX_RENEWALS_REACHED */,
					7009 /* CIRC_CLAIMS_RETURNED */,
					7010 /* COPY_ALERT_MESSAGE */,
					7013 /* PATRON_EXCEEDS_FINES */,
				],
				'text' : {
					'1212' : function(r) { return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode', [barcode]); },
					'1213' : function(r) { return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode', [barcode]); },
					'1215' : function(r) { return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode', [barcode]); },
					'7002' : function(r) { return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode', [barcode]); },
					'7003' : function(r) { return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode', [barcode]); },
					'7004' : function(r) {
						return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode.status', [barcode, r.payload.status().name()]);
					},
					'7006' : function(r) { return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode', [barcode]); },
					'7007' : function(r) { return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode', [barcode]); },
					'7008' : function(r) { return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode', [barcode]); },
					'7009' : function(r) { return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode', [barcode]); },
					'7010' : function(r) {
						return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode.msg', [barcode, r.payload]);
					},
					'7013' : function(r) { return document.getElementById('circStrings').getFormattedString('staff.circ.renew.barcode', [barcode]); }
				}
			}
		);
		if (! async ) {
			return renew_callback( { 'getResultObject' : function() { return renew; } } );
		}

	} catch(E) {
		JSAN.use('util.error'); var error = new util.error();
		error.standard_unexpected_error_alert(document.getElementById('circStrings').getFormattedString('staff.circ.checkin.renew_failed.error', [barcode]), E);
		return null;
	}
};

dump('exiting circ/util.js\n');
