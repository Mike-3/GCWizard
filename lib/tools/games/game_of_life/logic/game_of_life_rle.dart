var sizeRegex = RegExp(r'^[xX]\s*=\s*(\d+)\s*,\s*[yY]\s*=\s*(\d+)');
var ruleRegex = RegExp(r',\s*rule\s*=\s*(.*)');
var sequenceRegex = RegExp(r'(.*?)[$!]', multiLine: true);
var stateRegex = RegExp(r'(\d*)([bo])', multiLine: true);

