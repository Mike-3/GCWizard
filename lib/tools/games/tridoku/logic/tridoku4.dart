

import 'package:gc_wizard/tools/games/sudoku/logic/sudoku_solver.dart';

List<List<List<int>>> solutions = [];

class TridokuSolver {
  late List<List<SudokuBoardValue>> board;

  var rows = <List<SudokuBoardValue>>{};

  TridokuSolver(List<List<int>> grid) {
    // board = List<List<SudokuBoardValue?>>.generate(9, (index) => List<SudokuBoardValue?>.generate((index * 2) + 1, (index) => null));
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < (row * 2) + 1; col++) {
        board[row][col] = SudokuBoardValue(grid[row][col], grid[row][col] != 0 ? SudokuFillType.USER_FILLED: SudokuFillType.CALCULATED);
      }
    }
    // white
    rows.add([board[1][1], board[2][1], board[2][2], board[2][3], board[3][1], board[3][2], board[3][3], board[3][4], board[3][5]]);
    rows.add([board[5][3], board[5][4], board[5][5], board[5][6], board[5][7], board[6][5], board[6][5], board[6][7], board[7][7]]);
    rows.add([board[6][1], board[6][2], board[7][1], board[7][2], board[7][3], board[7][4], board[8][1], board[8][3], board[8][5]]);
    rows.add([board[6][10], board[6][11], board[7][10], board[7][11], board[7][12], board[7][13], board[8][11], board[8][13], board[8][15]]);
    // blue
    rows.add([board[0][0], board[1][0], board[2][0], board[3][0], board[4][0], board[5][0], board[6][0], board[7][0], board[8][0]]);
    rows.add([board[8][0], board[8][2], board[8][4], board[8][6], board[8][8], board[8][10], board[8][12], board[8][14], board[8][16]]);
    rows.add([board[0][0], board[1][2], board[2][4], board[3][6], board[4][8], board[5][10], board[6][12], board[7][14], board[8][16]]);
    // yellow
    rows.add([board[4][0], board[4][1], board[4][2], board[4][3], board[4][4], board[4][5], board[4][6], board[4][7], board[4][8]]);
    rows.add([board[4][0], board[5][1], board[5][2], board[6][3], board[6][4], board[7][5], board[7][6], board[8][7], board[8][8]]);
    rows.add([board[4][8], board[5][8], board[5][9], board[6][8], board[6][9], board[7][8], board[7][9], board[8][8], board[8][9]]);

  }

  // Überprüft, ob eine Zahl in der Zeile zulässig ist
  bool isValidInRow(int row, int number) {
    for (int col = 0; col < board[row].length; col++) {
      if (board[row][col] == number) {
        return false;
      }
    }
    return true;
  }

  // Überprüft, ob eine Zahl in der Spalte zulässig ist
  bool isValidInCol(int col, int number) {
    for (int row = 0; row < board.length; row++) {
      if (col < board[row].length && board[row][col] == number) {
        return false;
      }
    }
    return true;
  }

  // Überprüft, ob eine Zahl im Dreieck zulässig ist
  bool isValidInTriangle(int row, int col, int number) {
    // Hier müsste ein Mapping zu den Dreiecken erstellt werden,
    // da jedes der großen Dreiecke 9 Felder umfasst.
    // Dies ist eine Vereinfachung und müsste an ein spezifisches Layout angepasst werden.
    return true;
  }

  // Überprüft, ob das Einfügen der Zahl in die Zelle zulässig ist
  bool isValidPlacement(int row, int col, int number) {
    return isValidInRow(row, number) &&
        isValidInCol(col, number) &&
        isValidInTriangle(row, col, number);
  }

  // Backtracking-Algorithmus zur Ermittlung aller Lösungen
  bool solve() {
    for (int row = 0; row < board.length; row++) {
      for (int col = 0; col < board[row].length; col++) {
        if (board[row][col] == 0) {
          for (int number = 1; number <= 9; number++) {
            if (isValidPlacement(row, col, number)) {
              board[row][col] = number;

              if (solve()) {
                // Sobald eine Lösung gefunden wurde, speichern
                solutions.add(board.map((row) => List<int>.from(row)).toList());
              }

              board[row][col] = 0; // Rücksetzen (Backtracking)
            }
          }
          return false; // Kein gültiger Wert gefunden, Backtracking
        }
      }
    }
    return true; // Puzzle gelöst
  }

  // Druckt das Tridoku-Gitter in dreieckiger Form
  void printTriangleGrid(List<List<int>> grid) {
    for (int row = 0; row < grid.length; row++) {
      // Einrücken für die dreieckige Darstellung
      String indent = ' ' * (grid.length - row - 1);
      print(indent + grid[row].map((val) => val.toString()).join(' '));
    }
  }
}

void main() {
  // Tridoku Puzzle mit variabler Anzahl an Feldern pro Zeile (jeweils 2 Felder mehr pro Zeile)
  List<List<int>> puzzle = [
    [5],                    // 1. Zeile: 1 Feld
    [0, 3, 0],              // 2. Zeile: 3 Felder
    [6, 0, 0, 7, 0],        // 3. Zeile: 5 Felder
    [0, 0, 0, 0, 0, 0, 0],  // 4. Zeile: 7 Felder
    [0, 0, 0, 0, 9, 0, 0, 0, 0],  // 5. Zeile: 9 Felder
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // 6. Zeile: 11 Felder
    [0, 0, 0, 6, 0, 0, 0, 0, 0, 0, 0, 0, 0], // 7. Zeile: 13 Felder
    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // 8. Zeile: 15 Felder
    [4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], // 9. Zeile: 17 Felder
  ];

  TridokuSolver solver = TridokuSolver(puzzle);

  solver.solve();

  if (solutions.isNotEmpty) {
    print('Es wurden ${solutions.length} Lösungen gefunden:');
    for (var solution in solutions) {
      solver.printTriangleGrid(solution);
      print('\n');
    }
  } else {
    print('Keine Lösung möglich');
  }
}
