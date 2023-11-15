import "package:flutter_test/flutter_test.dart";
import 'package:gc_wizard/tools/games/tetris/logic/TetrisPuzzleSolver.dart';
import 'package:gc_wizard/tools/games/tetris/logic/TetrisPuzzleSolverMT.dart';

void main() {
  group("Tetris.solve:", () {
    List<Map<String, Object?>> _inputsToExpected = [
      {'inputSize' : [8, 6],
        'inputCounts' : [1, 6, 2, 0, 0, 1, 2],
        'expectedOutput' : true,
        'solutionCount': 1
      },
    ];

    for (var elem in _inputsToExpected) {
      test('size: ${elem['inputSize']} counts: ${elem['inputCounts']}', () async {
        var size = elem['inputSize'] as List<int>;
        var counts = elem['inputCounts'] as List<int>;
        var _actual = TetrisPuzzleSolverMT(size[0], size[1], counts[0], counts[1], counts[2], counts[3], counts[4], counts[5], counts[6]);
        var result = await _actual.solve();
        result = result;
        expect(result, elem['expectedOutput']);
        //expect(_actual.solutions?[0].solution, elem['expectedOutput']);
        //expect(_actual.solutions?.length, elem['solutionCount']);
      });
    }
  });
}