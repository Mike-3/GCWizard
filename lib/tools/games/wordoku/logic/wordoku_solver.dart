import 'dart:math';

import 'package:gc_wizard/tools/games/sudoku/logic/external_libs/dartist.sudoku_solver/sudoku.dart';

enum WordokuFillType { USER_FILLED, CALCULATED }

class WordokuBoardValue {
  WordokuFillType type;
  String? value;

  WordokuBoardValue(this.value, this.type);
}

class WordokuBoard {
  late List<List<WordokuBoardValue?>> board;
  List<_WordokuSolution>? solutions;

  WordokuBoard({List<List<String>>? board}) {
    this.board =
        List<List<WordokuBoardValue?>>.generate(9, (index) => List<WordokuBoardValue?>.generate(9, (index) => null));

    if (board != null) {
      for (int i = 0; i < min(board.length, this.board.length); i++) {
        for (int j = 0; j < min(board[i].length, this.board[i].length); j++) {
          if (board[i][j].isNotEmpty) {
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
    return board[i][j]?.value;
  }

  WordokuFillType getFillType(int i, int j) {
    return (board[i][j] == null || board[i][j]!.type == WordokuFillType.CALCULATED)
        ? WordokuFillType.CALCULATED
        : WordokuFillType.USER_FILLED;
  }

  void solveSudoku(int maxSolutions) {
    var solutions = solve(_solveableBoard(), maxSolutions: maxSolutions);
    if (solutions == null) {
      this.solutions = null;
      return;
    }

    this.solutions = solutions.map((solution) => _WordokuSolution(solution)).toList();
  }

  List<List<int>> _solveableBoard() {
    return board.map((column) {
      return column
          .map((row) => row != null && row.type == WordokuFillType.USER_FILLED
              ? (row.value is int)
                  ? row.value as int
                  : 0
              : 0)
          .toList();
    }).toList();
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
        if (getFillType(i, j) == WordokuFillType.USER_FILLED) continue;
        setValue(i, j, solutions![solutionIndex].getValue(i, j), WordokuFillType.CALCULATED);
      }
    }
  }
}

class _WordokuSolution {
  final List<List<String>> solution;

  _WordokuSolution(this.solution);

  String? getValue(int i, int j) {
    if (i < 0 || i >= solution.length || j < 0 || j >= solution[i].length) return null;
    return solution[i][j];
  }
}
