var records = new Array();
var ranks = new Array();
var table;
var rowtemplate;

function mresultUnload() { removeChildren(table); table = null;}


function mresultDoSearch() {

	table = G.ui.result.main_table;
	rowtemplate = table.removeChild(G.ui.result.row_template);
	removeChildren(table);

	if(getOffset() == 0 || getHitCount() == null ) {
		mresultGetCount();
		mresultCollectIds();
	} else { 
		resultSetInfo();
		mresultCollectIds();
	}
}

function mresultGetCount() {
	var req = new Request(FETCH_MRCOUNT, 
			getStype(), getTerm(), getLocation(), getDepth(), getForm() );
	req.callback(mresultHandleCount);
	req.send();
}

function mresultHandleCount(r) {
	HITCOUNT = parseInt(r.getResultObject());
	resultSetInfo(); 
}


/* performs the actual search */
function mresultCollectIds() {
	var req = new Request(FETCH_MRIDS, getStype(), getTerm(), 
			getLocation(), getDepth(), getDisplayCount(), getOffset(), getForm() );
	req.callback(mresultHandleMRIds);
	req.send();
}

function mresultHandleMRIds(r) {
	mresultSetRecords(r.getResultObject().ids);
	mresultCollectRecords(); 
}

function mresultSetRecords(idstruct) {
	var o = getOffset();
	for( var x = o; x!= idstruct.length + o; x++ ) {
		records[x] = idstruct[x - o][0];
		ranks[x] = idstruct[x - o][1];
	}
}

function mresultHandleMods(r) {
	var rec = r.getResultObject();
	resultDisplayRecord(rec, rowtemplate, true);
	resultCollectCopyCounts(rec, FETCH_MR_COPY_COUNTS);
}


function mresultCollectRecords() {
	for( var x = getOffset(); x!= getDisplayCount() + getOffset(); x++ ) {
		if(isNull(records[x])) break;
		var req = new Request(FETCH_MRMODS, records[x]);
		req.callback(mresultHandleMods);
		req.send();
	}
}


