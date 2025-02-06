int _MAX_SOLUTIONS = 1000;
int _FOUND_SOLUTIONS = 0;

// ... (Hilfsfunktionen _cross, _all, _order bleiben gleich)

const String _digits = '123456789';
// **Wichtig:** Definiere _rows und _cols entsprechend der maximalen Größe deines Tridokus
const String _rows = '123456789'; // Beispiel: Für ein 9-zeiliges Tridoku
const String _cols = 'ABCDEFGHI'; // Beispiel: Für ein 9-spaltiges Tridoku

// Erstelle _squares basierend auf den tatsächlichen Zellen des Tridokus
List<String> _squares = [];
// **Wichtig:** Fülle _squares mit den tatsächlichen Zellbezeichnungen deines Tridokus
// Beispiel: _squares.addAll(['A1', 'B1', 'B2', 'C1', 'C2', 'C3', ...]);

// _unitlist muss nun **dynamisch** erstellt werden, basierend auf _squares
List<List<String>> _unitlist = [];

// Füge Zeilen hinzu
for (var r in _rows.split('')) {
_unitlist.add(_squares.where((s) => s.startsWith(r)).toList());
}

// Füge Spalten hinzu
for (var c in _cols.split('')) {
_unitlist.add(_squares.where((s) => s.endsWith(c)).toList());
}

// **Entscheidend:** Füge die Tridoku-Regionen hinzu
// **Wichtig:** Definiere die Tridoku-Regionen basierend auf deinem spezifischen Tridoku-Format
_unitlist.addAll([
['A1', 'B2', 'C3', 'D4', 'E5', 'F6', 'G7', 'H8', 'I9'], // Beispiel-Diagonale
// ... weitere Tridoku-Regionen
]);

// ... (_units und _peers werden basierend auf _squares und _unitlist erstellt)

/// Parse a Grid (angepasst für dein Tridoku-Format)
Map<String, String>? _parse_grid(List<List<int>> grid) {
Map<String, String> values = _squares
    .map((String s) => <String>[s, _digits])
    .fold(<String, String>{}, (map, kv) => map..putIfAbsent(kv[0], () => kv[1]));

// **Wichtig:** Passe _grid_values an dein Tridoku-Format an
Map<String, String> gridValues = _grid_values(grid);

for (var s in gridValues.keys) {
var d = gridValues[s]!;
if (d != '0' && _digits.contains(d) && _assign(values, s, d) == null) return null;
}

return values;
}

// **Wichtig:** Passe _grid_values an dein Tridoku-Format an
Map<String, String> _grid_values(List<List<int>> grid) {
Map<String, String> gridMap = {};
int row = 0;
for (var r in _rows.split('')) {
for (int col = 0; col < grid[row].length; col++) {
gridMap[r + _cols[col]] = grid[row][col].toString();
}
row++;
}
return gridMap;
}

// ... (_assign, _eliminate, solve, _searchAll bleiben im Wesentlichen gleich)

void main() {
// **Wichtig:** Definiere dein Tridoku-Puzzle im richtigen Format
List<List<int>> puzzle1 = [
[6],
[0, 0, 4],
[0, 2, 0, 8, 0],
[0, 0, 3, 0, 7, 2, 1],
[0, 0, 1, 0, 0, 0, 0, 5, 0],
[0, 0, 0, 0, 2, 0, 0, 0, 8, 0, 3],
[0, 6, 0, 0, 5, 0, 0, 3, 0, 0, 7, 0, 8],
[0, 0, 5, 3, 7, 0, 0, 1, 0, 0, 6, 5, 4, 0, 0],
[0, 1, 0, 4, 0, 0, 0, 6, 0, 0, 4, 0, 2, 0, 0, 3, 0],
];

// ... (Aufruf von solve und Ausgabe der Ergebnisse)
}




// Bitte analysiere folgenden Dart Code, der dazu dient ein Sudoku zu lösen. Passe ihn dann an um ein Tridoku zu lösen.
//
// Im Main steht ein zu lösenden Beispiel Tridoku.
//
//
// int _MAX_SOLUTIONS = 1000;
// int _FOUND_SOLUTIONS = 0;
//
// List<String> _cross(String A, String B) => A.split('').expand((a) => B.split('').map((b) => a + b)).toList();
//
// const String _digits = '123456789';
// const String _rows = '123456789';
// const String _cols = 'ABCDEFGHI';
// final List<String> _squares = _cross(_rows, _cols);
//
// final List<List<String>> _unitlist = _cols.split('').map((c) => _cross(_rows, c)).toList()
// ..addAll(_rows.split('').map((r) => _cross(r, _cols)))
// ..addAll(['ABC', 'DEF', 'GHI'].expand((rs) => ['123', '456', '789'].map((cs) => _cross(rs, cs))));
//
// final Map<String, List<List<String>>> _units = _squares
//     .map((s) => MapEntry<String, List<List<String>>>(s, _unitlist.where((u) => u.contains(s)).toList()))
//     .fold(<String, List<List<String>>>{}, (map, kv) => map..putIfAbsent(kv.key, () => kv.value));
//
// final Map<String, Set<String>> _peers = _squares
//     .map((s) => MapEntry<String, Set<String>>(s, _units[s]!.expand((u) => u).toSet()..removeAll([s])))
//     .fold(<String, Set<String>>{}, (map, kv) => map..putIfAbsent(kv.key, () => kv.value));
//
// /// Parse a Grid
// Map<String, String>? _parse_grid(List<List<int>> grid) {
// Map<String, String> values = _squares
//     .map((String s) => <String>[s, _digits])
//     .fold(<String, String>{}, (map, kv) => map..putIfAbsent(kv[0], () => kv[1]));
// var gridValues = _grid_values(grid);
//
// for (var s in gridValues.keys) {
// var d = gridValues[s]!;
// if (_digits.contains(d) && _assign(values, s, d) == null) return null;
// }
//
// return values;
// }
//
// Map<String, String> _grid_values(List<List<int>> grid) {
// Map<String, String> gridMap = {};
// for (int i = 0; i < 9; i++) {
// for (int j = 0; j < 9; j++) {
// gridMap.putIfAbsent(_rows[i] + _cols[j], () => grid[i][j].toString());
// }
// }
//
// return gridMap;
// }
//
// /// Constraint Propagation
// Map<String, String>? _assign(Map<String, String> values, String s, String d) {
// var other_values = values[s]!.replaceAll(d, '');
//
// if (_all(other_values.split('').map((d2) => _eliminate(values, s, d2)))) return values;
// return null;
// }
//
// Map<String, String>? _eliminate(Map<String, String> values, String s, String d) {
// if (!values[s]!.contains(d)) return values;
// values[s] = values[s]!.replaceAll(d, '');
// if (values[s]!.isEmpty) {
// return null;
// } else if (values[s]!.length == 1) {
// var d2 = values[s]!;
// if (!_all(_peers[s]!.map((s2) => _eliminate(values, s2, d2)))) return null;
// }
//
// for (List<String> u in _units[s]!) {
// var dplaces = u.where((s) => values[s]!.contains(d));
// if (dplaces.isEmpty) {
// return null;
// } else if (dplaces.length == 1) {
// if (_assign(values, dplaces.elementAt(0), d) == null) {
// return null;
// }
// }
// }
// return values;
// }
//
// /// Search
// List<List<List<int>>>? solve(List<List<int>> grid, {int? maxSolutions}) {
// if (maxSolutions != null && maxSolutions > 0) _MAX_SOLUTIONS = maxSolutions;
//
// _FOUND_SOLUTIONS = 0;
//
// var results = _searchAll(_parse_grid(grid));
// if (results == null || results.isEmpty) return null;
//
// List<List<List<int>>> outputs = [];
//
// for (Map<String, String> result in results) {
// List<List<int>> output = [];
// for (int i = 0; i < 9; i++) {
// var column = <int>[];
// for (int j = 0; j < 9; j++) {
// column.add(int.parse(result[_rows[i] + _cols[j]]!));
// }
// output.add(column);
// }
// outputs.add(output);
// }
//
// return outputs;
// }
//
// List<Map<String, String>>? _searchAll(Map<String, String>? values) {
// if (values == null || _FOUND_SOLUTIONS >= _MAX_SOLUTIONS) return null;
//
// if (_squares.every((String s) => values[s]!.length == 1)) {
// _FOUND_SOLUTIONS++;
// return <Map<String, String>>[values];
// }
//
// var s2 =
// _order(_squares.where((String s) => values[s]!.length > 1).toList(), on: (String s) => values[s]!.length).first;
//
// var output = <Map<String, String>>[];
//
// values[s2]!.split('').forEach((d) {
// var result = _searchAll(_assign(Map<String, String>.from(values), s2, d));
// if (result == null) return;
//
// output.addAll(result);
// });
//
// return output;
// }
//
// List<String> _order(List<String> seq,
// {Comparator<String>? by, List<Comparator<String>>? byAll, required int Function(String x) on}) =>
// by != null
// ? (seq..sort(by))
//     : byAll != null
// ? (seq..sort((a, b) => byAll.firstWhere((compare) => compare(a, b) != 0, orElse: () => (x, y) => 0)(a, b)))
//     : (seq..sort((a, b) => on(a).compareTo(on(b))));
//
// bool _all(Iterable<Map<String, String>?> seq) => seq.every((e) => e != null);
//
//
//
//
//
//
// void main() {
//
// List<List<int>> puzzle1 = [
//
// [6],
// [0, 0, 4],
// [0, 2, 0, 8, 0],
// [0, 0, 3, 0, 7, 2, 1],
// [0, 0, 1, 0, 0, 0, 0, 5, 0],
// [0, 0, 0, 0, 2, 0, 0, 0, 8, 0, 3],
// [0, 6, 0, 0, 5, 0, 0, 3, 0, 0, 7, 0, 8],
// [0, 0, 5, 3, 7, 0, 0, 1, 0, 0, 6, 5, 4, 0, 0],
// [0, 1, 0, 4, 0, 0, 0, 6, 0, 0, 4, 0, 2, 0, 0, 3, 0],
//
// ];
//
// solve(puzzle1);
//
// }