import 'dart:math';

import 'package:collection/collection.dart';
import 'package:gc_wizard/tools/games/sudoku/logic/external_libs/dartist.sudoku_solver/sudoku.dart';
import 'package:gc_wizard/utils/collection_utils.dart';
import 'package:gc_wizard/utils/string_utils.dart';

enum WordokuFillType { USER_FILLED, CALCULATED }

class WordokuBoardValue {
  WordokuFillType type;
  String? value;

  WordokuBoardValue(this.value, this.type);
}

class WordokuBoard {
  late List<List<WordokuBoardValue?>> board;
  List<_WordokuSolution>? solutions;
  var mapCharacter = 'ABCDEFGHI';
  var mapCharacterCalc = <int, String>{};

  WordokuBoard({List<List<String?>>? board, String? mapCharacter}) {
    this.board =
        List<List<WordokuBoardValue?>>.generate(9, (index) => List<WordokuBoardValue?>.generate(9, (index) => null));

    if (mapCharacter != null && mapCharacter.isNotEmpty) {
      this.mapCharacter = mapCharacter;
    }

    if (board != null) {
      for (int i = 0; i < min(board.length, this.board.length); i++) {
        for (int j = 0; j < min(board[i].length, this.board[i].length); j++) {
          if (board[i][j] != null && board[i][j]!.isNotEmpty) {
            setValue(i, j, board[i][j], WordokuFillType.USER_FILLED);
          }
        }
      }
    }
  }

  void setValue(int i, int j, String? value, WordokuFillType type) {
    board[i][j] = WordokuBoardValue(value, type);
  }

  String? getValue(int i, int j) {
    return _getValue(board[i][j]?.value);
  }

  String? _getValue(String? value) {
    return value != null && value.trim().isNotEmpty ? value : null;
  }

  WordokuFillType getFillType(int i, int j) {
    return (getValue(i, j) == null || board[i][j]!.type == WordokuFillType.CALCULATED)
        ? WordokuFillType.CALCULATED
        : WordokuFillType.USER_FILLED;
  }

  void solveSudoku(int maxSolutions) {
    var solutions = solve(_solveableBoard(), maxSolutions: maxSolutions);
    if (solutions == null) {
      this.solutions = null;
      return;
    }

    this.solutions = solutions.map((solution) => _WordokuSolution(_solvedBoard(solution))).toList();
  }

  List<List<int>> _solveableBoard() {
    _mapCharacterCalc();
    var map = switchMapKeyValue(mapCharacterCalc);

    int getNumber(String? char){
      if (char == null || !map.containsKey(char.toUpperCase())) return 0;
      return map[char.toUpperCase()]!;
    }

    return board.map((column) {
      return column
          .map((row) => row != null && row.type == WordokuFillType.USER_FILLED
              ? (row.value is String)
                  ? getNumber(_getValue(row.value))
                  : 0
              : 0)
          .toList();
    }).toList();
  }

  List<List<String?>> _solvedBoard(List<List<int>> solution) {
    String? getChar(int value){
      return mapCharacterCalc[value];
    }

    return board.mapIndexed((columnIndex, column) {
      return column
          .mapIndexed((rowIndex, row) => row != null && row.type == WordokuFillType.USER_FILLED
              ? (row.value is String)
                  ? row.value
                  : null
              : getChar(solution[columnIndex][rowIndex]))
          .toList();
    }).toList();
  }

  String mapCharacterCleaned() {
    var cleaned =  mapCharacter.trim().replaceAll(RegExp(r'\s+'), '');
    cleaned = removeDuplicateCharacters(cleaned.toUpperCase());

    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (getFillType(i, j) == WordokuFillType.USER_FILLED) {
          var value = getValue(i, j);
          if (value != null && !cleaned.contains(value.toUpperCase())) {
            cleaned = value.toUpperCase() + cleaned;
          }
        }
      }
    }
    return cleaned.substring(0, min(9, cleaned.length));
  }

  void _mapCharacterCalc() {
    var chars = mapCharacterCleaned();
    mapCharacterCalc.clear();
    for (int i = 0; i < chars.length; i++) {
      mapCharacterCalc.addAll({i+1: chars[i]});
    }

    var fillCharacter = {'1', '2', '3', '4', '5', '6', '7', '8', '9'};
    if (mapCharacterCalc.length < 9) {
      for (var digit in mapCharacterCalc.keys) {
        fillCharacter.remove(digit);
      }

      while (mapCharacterCalc.length < 9) {
        mapCharacterCalc.addAll({mapCharacterCalc.length: fillCharacter.first}) ;
        fillCharacter.remove(fillCharacter.first);
      }
    }
  }

  void removeCalculated() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (getFillType(i, j) == WordokuFillType.CALCULATED) setValue(i, j, null, WordokuFillType.CALCULATED);
      }
    }
    solutions = null;
  }

  void mergeSolution(int solutionIndex) {
    if (solutions == null || solutionIndex < 0 || solutionIndex >= solutions!.length) return;
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        setValue(i, j, solutions![solutionIndex].getValue(i, j), getFillType(i, j));
      }
    }
  }
}

class _WordokuSolution {
  final List<List<String?>> solution;

  _WordokuSolution(this.solution);

  String? getValue(int i, int j) {
    if (i < 0 || i >= solution.length || j < 0 || j >= solution[i].length) return null;
    return solution[i][j];
  }
}
