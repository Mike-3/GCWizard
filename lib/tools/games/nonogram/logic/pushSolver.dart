import 'package:collection/collection.dart';

bool _shouldSkip(List<int> line, int hint, int i) {
  var allZeros = line[i - 1] == 0;
  var collision = line[i + hint] == 1;
  for (var x = i; x < i + hint; x++) {
    if (line[x] == -1 || x >= line.length) {
      collision = true;
      break;
    }
    if (line[x] != 0) {
      allZeros = false;
    }
  }
  return allZeros || collision;
}

List<int>? pushLeft(List<int> line, List<int> hints) {
  if (hints.isEmpty) {
    return line.contains(1) ? null : line;
  }
  var hint = hints[0];
  var maxIndex = line.indexOf(1);
  if (maxIndex == -1) {
    maxIndex = line.length - hint;
  }
  for (var i = 0; i <= maxIndex; i++) {
    if (_shouldSkip(line, hint, i)) {
      continue;
    }
    var rest = pushLeft(line.slice(i + hint + 1), hints.slice(1));
    if (rest != null) {
      line = line.slice(0);
      for (var x = i; x < i + hint; x++) {
        line[x] = 1;
      }
      for (var x = 0; x < rest.length; x++) {
        line[x + i + hint + 1] = rest[x];
      }
      return line;
    }
  }
  return null;
}


void _enumerate(List<int> array) {
  for (var i = 0, j = array[0] % 2; i < array.length; i++) {
    if (array[i] == -1) { array[i] = 0;}
    if (array[i] % 2 != j % 2) {
      j++;
    }
    array[i] = j;
  }
}

List<int>? solve(List<int> line, List<int> hints) {
  var leftmost = pushLeft(line, hints);
  if (leftmost == null) {
    return null;
  }

  var reverseLine = line.slice(0).toList().reversed.toList();
  var reverseHints = hints.slice(0).toList().reversed.toList();
  var rightmost = pushLeft(reverseLine, reverseHints)!.reversed.toList();

  _enumerate(leftmost);
  _enumerate(rightmost);

  return leftmost.mapIndexed((el, i) {
    if (el == rightmost[i]) {
      return (el % 2 != 0) ? 1 : -1;
    }
    return line[i];
  }).toList();
}

// solve.speed = 'fast';
//
// module.exports = {solve, pushLeft};