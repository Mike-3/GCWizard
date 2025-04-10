int _MAX_SOLUTIONS = 1000;
int _FOUND_SOLUTIONS = 0;

List<String> _cross(String A, String B) => A.split('').expand((a) => B.split('').map((b) => a + b)).toList();

const String _digits = '123456789';
const String _rows = _digits;
const String _cols = 'ABCDEFGHI';
final List<String> _squares = _cross(_rows, _cols);

final List<List<String>> _unitlist = _cols.split('').map((c) => _cross(_rows, c)).toList()
  ..addAll(_rows.split('').map((r) => _cross(r, _cols)))
  ..addAll(['ABC', 'DEF', 'GHI'].expand((rs) => ['123', '456', '789'].map((cs) => _cross(rs, cs))));

final Map<String, List<List<String>>> _units = _squares
    .map((s) => MapEntry<String, List<List<String>>>(s, _unitlist.where((u) => u.contains(s)).toList()))
    .fold(<String, List<List<String>>>{}, (map, kv) => map..putIfAbsent(kv.key, () => kv.value));

final Map<String, Set<String>> _peers = _squares
    .map((s) => MapEntry<String, Set<String>>(s, _units[s]!.expand((u) => u).toSet()..removeAll([s])))
    .fold(<String, Set<String>>{}, (map, kv) => map..putIfAbsent(kv.key, () => kv.value));

/// Parse a Grid
Map<String, String>? _parse_grid(List<List<int>> grid) {
  Map<String, String> values = _squares
      .map((String s) => <String>[s, _digits])
      .fold(<String, String>{}, (map, kv) => map..putIfAbsent(kv[0], () => kv[1]));
  var gridValues = _grid_values(grid);

  for (var s in gridValues.keys) {
    var d = gridValues[s]!;
    if (_digits.contains(d) && _assign(values, s, d) == null) return null;
  }

  return values;
}

Map<String, String> _grid_values(List<List<int>> grid) {
  Map<String, String> gridMap = {};
  for (int i = 0; i < 9; i++) {
    for (int j = 0; j < 9; j++) {
      gridMap.putIfAbsent(_rows[i] + _cols[j], () => grid[i][j].toString());
    }
  }

  return gridMap;
}

/// Constraint Propagation
Map<String, String>? _assign(Map<String, String> values, String s, String d) {
  var other_values = values[s]!.replaceAll(d, '');
  print(s + ' 1: ' + values[s].toString() + ' ' + other_values.toString());
  if (_all(other_values.split('').map((d2) => _eliminate(values, s, d2)))) return values;
  print(s + ' :  null');
  return null;
}

Map<String, String>? _eliminate(Map<String, String> values, String s, String d) {
  if (!values[s]!.contains(d)) return values;
  print(s + ' 2: ' + values[s].toString());
  values[s] = values[s]!.replaceAll(d, '');
  print(s + '_2: ' + values[s].toString());
  if (values[s]!.isEmpty) {
    return null;
  } else if (values[s]!.length == 1) {
    print(s + ' 3: ' + values[s].toString());
    var d2 = values[s]!;
    if (!_all(_peers[s]!.map((s2) => _eliminate(values, s2, d2)))) return null;
  }

  for (List<String> u in _units[s]!) {
    var dplaces = u.where((s) => values[s]!.contains(d));
    if (dplaces.isEmpty) {
      return null;
    } else if (dplaces.length == 1) {
      if (_assign(values, dplaces.elementAt(0), d) == null) {
        return null;
      }
    }
  }
  return values;
}

/// Search
List<List<List<int>>>? solve(List<List<int>> grid, {int? maxSolutions}) {
  if (maxSolutions != null && maxSolutions > 0) _MAX_SOLUTIONS = maxSolutions;

  _FOUND_SOLUTIONS = 0;

  var results = _searchAll(_parse_grid(grid));
  if (results == null || results.isEmpty) return null;

  List<List<List<int>>> outputs = [];

  for (Map<String, String> result in results) {
    List<List<int>> output = [];
    for (int i = 0; i < 9; i++) {
      var column = <int>[];
      for (int j = 0; j < 9; j++) {
        column.add(int.parse(result[_rows[i] + _cols[j]]!));
      }
      output.add(column);
    }
    outputs.add(output);
  }

  return outputs;
}

List<Map<String, String>>? _searchAll(Map<String, String>? values) {
  if (values == null || _FOUND_SOLUTIONS >= _MAX_SOLUTIONS) return null;

  if (_squares.every((String s) => values[s]!.length == 1)) {
    _FOUND_SOLUTIONS++;
    return <Map<String, String>>[values];
  }

  var s2 =
      _order(_squares.where((String s) => values[s]!.length > 1).toList(), on: (String s) => values[s]!.length).first;

  var output = <Map<String, String>>[];

  values[s2]!.split('').forEach((d) {
    var result = _searchAll(_assign(Map<String, String>.from(values), s2, d));
    if (result == null) return;

    output.addAll(result);
  });

  return output;
}

List<String> _order(List<String> seq,
    {Comparator<String>? by, List<Comparator<String>>? byAll, required int Function(String x) on}) =>
    by != null
        ? (seq..sort(by))
        : byAll != null
        ? (seq..sort((a, b) => byAll.firstWhere((compare) => compare(a, b) != 0, orElse: () => (x, y) => 0)(a, b)))
        : (seq..sort((a, b) => on(a).compareTo(on(b))));

bool _all(Iterable<Map<String, String>?> seq) => seq.every((e) => e != null);

void main() {
  // https://www.geocaching.com/seek/cache_details.aspx?wp=GC4NJH1&title=#:~:text=Die%20Regeln%20des%20Tridoku%20sind,%C3%A4u%C3%9Feren%20schraffierten%20Dreiecks%20angeordnet%20werden.
  List<List<int>> puzzle = [[4, 5, 0, 0, 0, 0, 0, 6, 0], [0, 0, 7, 9, 4, 0, 0, 0, 0], [0, 8, 0, 0, 0, 1, 0, 0, 7], [0, 0, 1, 0, 0, 0, 0, 0, 5], [0, 0, 8, 7, 0, 0, 4, 0, 0], [0, 6, 9, 4, 3, 0, 0, 0, 1], [0, 1, 0, 5, 6, 0, 0, 7, 2], [2, 0, 0, 1, 0, 0, 0, 0, 3], [0, 0, 0, 3, 0, 2, 0, 0, 0]];

  print(_unitlist);
  solve(puzzle);
  // print(solve(puzzle));
}
