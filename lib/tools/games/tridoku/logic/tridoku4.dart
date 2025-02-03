

import 'package:collection/collection.dart';
import 'package:gc_wizard/tools/games/sudoku/logic/sudoku_solver.dart';

List<List<List<int>>> solutions = [];

class TridokuSolver {
  late List<List<SudokuBoardValue>> board;

  var areas = <List<SudokuBoardValue>>{};

  TridokuSolver(List<List<int>> grid) {
    // board = List<List<SudokuBoardValue?>>.generate(9, (index) => List<SudokuBoardValue?>.generate((index * 2) + 1, (index) => null));
    solutions = [];
    board = [];
    int columnWidth(int row) => (row * 2) + 1;
    for (int row = 0; row < 9; row++) {
      board.add([]);
      for (int col = 0; col < columnWidth(row); col++) {
        board[row].add(SudokuBoardValue(grid[row][col], grid[row][col] != 0 ? SudokuFillType.USER_FILLED: SudokuFillType.CALCULATED));
      }
    }
    // white
    areas.add([board[1][1], board[2][1], board[2][2], board[2][3], board[3][1], board[3][2], board[3][3], board[3][4], board[3][5]]);
    areas.add([board[5][3], board[5][4], board[5][5], board[5][6], board[5][7], board[6][5], board[6][5], board[6][7], board[7][7]]);
    areas.add([board[6][1], board[6][2], board[7][1], board[7][2], board[7][3], board[7][4], board[8][1], board[8][3], board[8][5]]);
    areas.add([board[6][10], board[6][11], board[7][10], board[7][11], board[7][12], board[7][13], board[8][11], board[8][13], board[8][15]]);
    // blue
    areas.add([board[0][0], board[1][0], board[2][0], board[3][0], board[4][0], board[5][0], board[6][0], board[7][0], board[8][0]]);
    areas.add([board[8][0], board[8][2], board[8][4], board[8][6], board[8][8], board[8][10], board[8][12], board[8][14], board[8][16]]);
    areas.add([board[0][0], board[1][2], board[2][4], board[3][6], board[4][8], board[5][10], board[6][12], board[7][14], board[8][16]]);
    // yellow
    areas.add([board[4][0], board[4][1], board[4][2], board[4][3], board[4][4], board[4][5], board[4][6], board[4][7], board[4][8]]);
    areas.add([board[4][0], board[5][1], board[5][2], board[6][3], board[6][4], board[7][5], board[7][6], board[8][7], board[8][8]]);
    areas.add([board[4][8], board[5][8], board[5][9], board[6][8], board[6][9], board[7][8], board[7][9], board[8][8], board[8][9]]);

    void addTriangle(int startRow, int startColum) {
      var triangele = <SudokuBoardValue>[];
      for (int row = startRow; row < startRow + 3; row++) {
        for (int col = startColum; col < startColum + columnWidth(row - startRow); col++) {
          triangele.add(board[row][col]);
        }
      }
      areas.add(triangele);
    }
    void addTriangleM(int startRow, int startColum) {
      var triangele = <SudokuBoardValue>[];
      for (int row = startRow; row < startRow + 3; row++) {
        for (int col = startColum; col < startColum + columnWidth(2 - row - startRow); col++) {
          triangele.add(board[row][col]);
        }
      }
      areas.add(triangele);
    }
    addTriangle(0, 0);
    addTriangle(3, 0);
    addTriangle(6, 0);
    addTriangle(3, 6);
    addTriangle(6, 12);
    addTriangle(6, 6);

    addTriangleM(3, 1);
    addTriangleM(6, 1);
    addTriangleM(6, 7);
  }

  // Überprüft, ob eine Zahl in der Zeile zulässig ist
  bool isValidInAreas(SudokuBoardValue entry, int number) {
    var toChecked = areas.where((area) => area.contains(entry));
    var valid = toChecked.any((area) => area.any((field) => field.value == number && field != entry));

    var rowIndex = board.indexOf(board.firstWhere((row) => row.contains(entry)));
    var columnIndex = board[rowIndex].indexOf(entry);

if (rowIndex == 5 && columnIndex == 0 && number == 1) {
  var value1 = areas.elementAt(4).any((field) => field.value == number && field != entry);
  var value2 = areas.elementAt(11).any((field) => field.value == number && field != entry);
  var ares = toChecked.map((area) => areas.toList().indexOf(area)).toList().toString();
  print(areas.elementAt(4).map((entry) => entry.value).toList().toString() + ' ' + valid.toString() + ' ' + ares);
  print(areas.elementAt(11).map((entry) => entry.value).toList().toString() + ' ' + valid.toString() + ' ' + ares);
  if (!value1 && !value2) {
    print('000');
  }
}
    // if (rowIndex == 0 && columnIndex == 0) {
    //   print(toChecked.map((area) => areas.toList().indexOf(area)).toList());
    // }
    return !valid;
  }

  bool isValidInContact(SudokuBoardValue entry, int number) {
    var rowIndex = board.indexOf(board.firstWhere((row) => row.contains(entry)));
    var columnIndex = board[rowIndex].indexOf(entry);

    bool isValidEntry(int _rowIndex, int _columnIndex) {
      if (_rowIndex < 0 || _rowIndex >= board.length) {
        return false;
      } else if (_columnIndex < 0 || _columnIndex >= board[_rowIndex].length) {
        return false;
      }
      return true;
    }
    for (int row = rowIndex - 1; row <= rowIndex + 1; row++) {
      for (int col = columnIndex - 2; col <= columnIndex + 2; col++) {
        if (isValidEntry(row, col) && board[row][col] != entry) {
          if (board[row][col].value == number) return false;
        }
      }
    }
    return true;
  }

  // Überprüft, ob das Einfügen der Zahl in die Zelle zulässig ist
  bool isValidPlacement(SudokuBoardValue entry, int number) {
    return isValidInAreas(entry, number) && isValidInContact(entry, number);
  }

  // Backtracking-Algorithmus zur Ermittlung aller Lösungen
  bool solve() {
    for (int row = 0; row < board.length; row++) {
      for (int col = 0; col < board[row].length; col++) {
        if (board[row][col].value == 0) {
          for (int number = 1; number <= 9; number++) {
            if (isValidPlacement(board[row][col], number)) {
              board[row][col].value = number;

              if (solve()) {
                // Sobald eine Lösung gefunden wurde, speichern
                solutions.add(board.map((row) => List<int>.from(row.map((entry) => entry.value).toList()).toList()).toList());
                return true;
              }

              board[row][col].value = 0; // Rücksetzen (Backtracking)
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
      String indent = '  ' * (grid.length - row - 1);
      print(indent + grid[row].map((val) => val.toString()).join(' '));
    }
  }
}

void main() {
  // Tridoku Puzzle mit variabler Anzahl an Feldern pro Zeile (jeweils 2 Felder mehr pro Zeile)
  List<List<int>> puzzle = [
    [0],                    // 1. Zeile: 1 Feld
    [0, 0, 0],              // 2. Zeile: 3 Felder
    [5, 6, 0, 0, 8],        // 3. Zeile: 5 Felder
    [0, 0, 2, 0, 0, 3, 0],  // 4. Zeile: 7 Felder
    [0, 3, 0, 0, 0, 0, 0, 0, 0],  // 5. Zeile: 9 Felder
    [0, 4, 0, 6, 0, 0, 7, 3, 0, 0, 0], // 6. Zeile: 11 Felder
    [8, 6, 0, 9, 0, 0, 1, 9, 0, 0, 0, 1, 0], // 7. Zeile: 13 Felder
    [0, 0, 2, 4, 7, 0, 6, 0, 2, 0, 7, 3, 9, 8, 0], // 8. Zeile: 15 Felder
    [0, 0, 5, 0, 0, 0, 9, 0, 0, 0, 0, 0, 4, 1, 0, 0, 0], // 9. Zeile: 17 Felder
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
