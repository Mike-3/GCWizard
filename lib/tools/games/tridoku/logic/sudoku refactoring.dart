// ported and adjusted for Dart2+ from https://github.com/dartist/sudoku_solver
/**
    Copyright (c) 2013, Demis Bellot
    Copyright (c) 2013, Adam Singer
    Copyright (c) 2013, Matias Meno
    All rights reserved.

    Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 */

int _MAX_SOLUTIONS = 1000;
int _FOUND_SOLUTIONS = 0;

List<String> _cross(String A, String B) => A.split('').expand((a) => B.split('').map((b) => a + b)).toList();

const String _digits = '123456789';
const String _rows = '123456789';
const String _cols = 'ABCDEFGHIJKLMNOPQ';
final List<String> _squares = _cross(_rows, _cols);

final List<List<String>> _unitlist = [
  ['2B','3B','3C','3D','4B','4C','4D','4E','4F'], // white
  ['6D','6E','6F','6G','6H','7F','7F','7H','8H'],
  ['7B','7C','8B','8C','8D','8E','9B','9D','9F'],
  ['7K','7L','8K','8L','8M','8N','9L','9N','9P'],
  ['1A','2A','3A','4A','5A','6A','7A','8A','9A'], // blue
  ['9A','9C','9E','9G','9I','9K','9M','9O','9Q'],
  ['1A','2C','3E','4G','5I','6K','7M','8O','9Q'],
  ['5A','5B','5C','5D','5E','5F','5G','5H','5I'], // yellow
  ['5A','6B','6C','7D','7E','8F','8G','9H','9I'],
  ['5I','6I','6J','7I','7J','8I','8J','9I','9J'],
  ['1A','2A','2B','2C','3A','3B','3C','3D','3E'], // triangle
  ['4A','5A','5B','5C','6A','6B','6C','6D','6E'],
  ['7A','8A','8B','8C','9A','9B','9C','9D','9E'],
  ['4G','5G','5H','5I','6G','6H','6I','6J','6K'],
  ['7M','8M','8N','8O','9M','9N','9O','9P','9Q'],
  ['7G','8G','8H','8I','9G','9H','9I','9J','9K'],
  ['4B','4C','4D','4E','4F','5D','5E','5F','6F'],
  ['7B','7C','7D','7E','7F','8D','8E','8F','9F'],
  ['7H','7I','7J','7K','7L','8J','8K','8L','9L'],
['2A','2B','2C','3B','3C','3D'], // Hexagons
['4A','4B','4C','5B','5C','5D'],
['4C','4D','4E','5D','5E','5F'],
['4E','4F','4G','5F','5G','5H'],
['6A','6B','6C','7B','7C','7D'],
['6C','6D','6E','7D','7E','7F'],
['6E','6F','6G','7F','7G','7H'],
['6G','6H','6I','7H','7I','7J'],
['6I','6J','6K','7J','7K','7L'],
['8A','8B','8C','9B','9C','9D'],
['8C','8D','8E','9D','9E','9F'],
['8E','8F','8G','9F','9G','9H'],
['8G','8H','8I','9H','9I','9J'],
['8I','8J','8K','9J','9K','9L'],
['8K','8L','8M','9L','9M','9N'],
['8M','8N','8O','9N','9O','9P'],


// ['1A','2B'], // fields
// ['2A','2B','3B'],
// ['1A','2A','2B','2C'],
// ['2B','2C','3D'],
// ['3A','3B','4B'],
// ['2A','3A','3B','3C'],
// ['3B','3C','3D','4D'],
// ['2C','3C','3D','3E'],
// ['3D','3E','4F'],
// ['4A','4B','5B'],
// ['3A','4A','4B','4C'],
// ['4B','4C','4D','5D'],
// ['3C','4C','4D','4E'],
// ['4D','4E','4F','5F'],
// ['3E','4E','4F','4G'],
// ['4F','4G','5H'],
// ['5A','5B','6B'],
// ['4A','5A','5B','5C'],
// ['5B','5C','5D','6D'],
// ['4C','5C','5D','5E'],
// ['5D','5E','5F','6F'],
// ['4E','5E','5F','5G'],
// ['5F','5G','5H','6H'],
// ['4G','5G','5H','5I'],
// ['5H','5I','6J'],
// ['6A','6B','7B'],
// ['5A','6A','6B','6C'],
// ['6B','6C','6D','7D'],
// ['5C','6C','6D','6E'],
// ['6D','6E','6F','7F'],
// ['5E','6E','6F','6G'],
// ['6F','6G','6H','7H'],
// ['5G','6G','6H','6I'],
// ['6H','6I','6J','7J'],
// ['5I','6I','6J','6K'],
// ['6J','6K','7L'],
// ['7A','7B','8B'],
// ['6A','7A','7B','7C'],
// ['7B','7C','7D','8D'],
// ['6C','7C','7D','7E'],
// ['7D','7E','7F','8F'],
// ['6E','7E','7F','7G'],
// ['7F','7G','7H','8H'],
// ['6G','7G','7H','7I'],
// ['7H','7I','7J','8J'],
// ['6I','7I','7J','7K'],
// ['7J','7K','7L','8L'],
// ['6K','7K','7L','7M'],
// ['7L','7M','8N'],
// ['8A','8B','9B'],
// ['7A','8A','8B','8C'],
// ['8B','8C','8D','9D'],
// ['7C','8C','8D','8E'],
// ['8D','8E','8F','9F'],
// ['7E','8E','8F','8G'],
// ['8F','8G','8H','9H'],
// ['7G','8G','8H','8I'],
// ['8H','8I','8J','9J'],
// ['7I','8I','8J','8K'],
// ['8J','8K','8L','9L'],
// ['7K','8K','8L','8M'],
// ['8L','8M','8N','9N'],
// ['7M','8M','8N','8O'],
// ['8N','8O','9P'],
// ['9A','9B'],
// ['8A','9A','9B','9C'],
// ['9B','9C','9D'],
// ['8C','9C','9D','9E'],
// ['9D','9E','9F'],
// ['8E','9E','9F','9G'],
// ['9F','9G','9H'],
// ['8G','9G','9H','9I'],
// ['9H','9I','9J'],
// ['8I','9I','9J','9K'],
// ['9J','9K','9L'],
// ['8K','9K','9L','9M'],
// ['9L','9M','9N'],
// ['8M','9M','9N','9O'],
// ['9N','9O','9P'],
// ['8O','9O','9P','9Q'],
// ['9P','9Q']
];

final Map<String, List<List<String>>> _units = _squares
    .map((s) => MapEntry<String, List<List<String>>>(s, _unitlist.where((u) => u.contains(s)).toList()))
    .fold(<String, List<List<String>>>{}, (map, kv) => map..putIfAbsent(kv.key, () => kv.value));

final Map<String, Set<String>> _peers = _squares
    .map((s) => MapEntry<String, Set<String>>(s, _units[s]!.expand((u) => u).toSet()..removeAll([s])))
    .fold(<String, Set<String>>{}, (map, kv) => map..putIfAbsent(kv.key, () => kv.value));

/// Parse a Grid
Map<String, String>? _parse_grid(List<List<int>> grid) {
  // print(_unitlist);

  var s0= _squares.map((s) => MapEntry<String, List<List<String>>>(s, _unitlist.where((u) => u.contains(s)).toList()));
  //var s1= s0.first.fold(<String, Set<String>>{}, (map, kv) => map..putIfAbsent(kv.key, () => kv.value));
// print(s0);
  var s4 = _squares.map((String s) => <String>[s, _digits]);
  var s5 = s4.fold(<String, String>{}, (map, kv) => map..putIfAbsent(kv[0], () => kv[1]));

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
  int columnWidth(int row) => (row * 2) + 1;
  for (int i = 0; i < 9; i++) {
    for (int j = 0; j < columnWidth(i); j++) {
      gridMap.putIfAbsent(_rows[i] + _cols[j], () => grid[i][j].toString());
    }
  }

  return gridMap;
}

/// Constraint Propagation
Map<String, String>? _assign(Map<String, String> values, String s, String d) {
  var other_values = values[s]!.replaceAll(d, ''); // Zahl aus Lösungsmöglichkeit für eine Zelle entfernen
// print(other_values.split('').toList().toString() + ' ' + values[s].toString());
  print(s + '1: ' + values[s].toString()+ ' ' + other_values.toString());
  var t = (other_values.split('').map((d2) => _eliminate(values, s, d2)));
  if (_all(t)) return values;
  // if (_all(other_values.split('').map((d2) => _eliminate(values, s, d2)))) return values;
  return null;
}

Map<String, String>? _eliminate(Map<String, String> values, String s, String d) {
  // print(s + '12: ' + values[s].toString());
  if (!values[s]!.contains(d)) return values;
  // print(s + '2: ' + values[s].toString());
  values[s] = values[s]!.replaceAll(d, ''); // Zahl aus Lösungsmöglichkeit für eine Zelle entfernen
  print(s + ' remove: $d ' + values[s].toString());
  if (values[s]!.isEmpty) {
    return null; // keine gültige Lösung
  } else if (values[s]!.length == 1) {
    // print(s + '3: ' + values[s].toString());
    print(s + ' solution: ' + values[s].toString());
    var d2 = values[s]!; // Lösung für die Zelle gefunden
    if (!_all(_peers[s]!.map((s2) => _eliminate(values, s2, d2)))) return null;
  }

  // print(s + '4: ' + _units[s]!.toString());
  for (List<String> u in _units[s]!) {
    var dplaces = u.where((s) => values[s]!.contains(d));
    // print(s + '5: ' + dplaces.toString());
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
  List<List<int>> puzzle = [ //https://logic-masters.de/Raetselportal/Raetsel/zeigen.php?id=00056L
    [0],
    [0, 0, 0],
    [5, 6, 0, 0, 8],
    [0, 0, 2, 0, 0, 3, 0],
    [0, 3, 0, 0, 0, 0, 0, 0, 0],
    [0, 4, 0, 6, 0, 0, 7, 3, 0, 0, 0],
    [8, 6, 0, 9, 0, 0, 1, 9, 0, 0, 0, 1, 0],
    [0, 0, 2, 4, 7, 0, 6, 0, 2, 0, 7, 3, 9, 8, 0],
    [0, 0, 5, 0, 0, 0, 9, 0, 0, 0, 0, 0, 4, 1, 0, 0, 0],
  ];
  List<List<int>> puzzle1 = [ //https://logic-masters.de/Raetselportal/Raetsel/zeigen.php?chlang=en&id=000DEM
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
  print(solve(puzzle1));

  // (solve([[0, 0, 0, 0, 0, 4, 3, 0, 7], [9, 0, 0, 0, 6, 0, 0, 0, 0], [7, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 5, 0, 0, 7, 9, 4], [0, 6, 5, 0, 0, 0, 0, 0, 0], [0, 0, 0, 8, 0, 3, 0, 0, 0], [0, 5, 4, 0, 0, 0, 0, 6, 0], [0, 0, 0, 0, 0, 0, 0, 5, 9], [0, 0, 3, 4, 0, 8, 0, 0, 0]]));
  // print(solve([[0, 0, 0, 0, 0, 4, 3, 0, 7], [9, 0, 0, 0, 6, 0, 0, 0, 0], [7, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 5, 0, 0, 7, 9, 4], [0, 6, 5, 0, 0, 0, 0, 0, 0], [0, 0, 0, 8, 0, 3, 0, 0, 0], [0, 5, 4, 0, 0, 0, 0, 6, 0], [0, 0, 0, 0, 0, 0, 0, 5, 9], [0, 0, 3, 4, 0, 8, 0, 0, 0]]));
  // if (solve([[0, 0, 0, 0, 0, 4, 3, 0, 7], [9, 0, 0, 0, 6, 0, 0, 0, 0], [7, 0, 0, 0, 0, 0, 0, 0, 0], [0, 0, 0, 5, 0, 0, 7, 9, 4], [0, 6, 5, 0, 0, 0, 0, 0, 0], [0, 0, 0, 8, 0, 3, 0, 0, 0], [0, 5, 4, 0, 0, 0, 0, 6, 0], [0, 0, 0, 0, 0, 0, 0, 5, 9], [0, 0, 3, 4, 0, 8, 0, 0, 0]])) {
  //   print("Tridoku gelöst:");
  //   // printGrid(puzzle);
  // } else {
  //   print("Keine Lösung gefunden.");
  // }
}