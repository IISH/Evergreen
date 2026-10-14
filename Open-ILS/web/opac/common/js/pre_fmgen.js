const fmclasses = {};

// Assume _preload_fieldmapper_IDL is loaded via xhtml:
// <script language='javascript' src='/IDL2js'> </script>
for (var cls in _preload_fieldmapper_IDL) {
	fmclasses[cls] = [];
	if (_preload_fieldmapper_IDL[cls].fields) {
		console.log("fieldmapper adding functions for: " + cls);
		_preload_fieldmapper_IDL[cls].fields.forEach(function(f) {
			fmclasses[cls].push(f.name);
		});
	}
}