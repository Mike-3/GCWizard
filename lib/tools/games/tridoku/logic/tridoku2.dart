

List<List<List<int>>> solutions = [];

class TridokuSolver {
  List<List<int>> grid;

  TridokuSolver(this.grid);

  // Überprüft, ob eine Zahl in der Zeile zulässig ist
  bool isValidInRow(int row, int number) {
    for (int col = 0; col < grid[row].length; col++) {
      if (grid[row][col] == number) {
        return false;
      }
    }
    return true;
  }

  // Überprüft, ob eine Zahl in der Spalte zulässig ist
  bool isValidInCol(int col, int number) {
    for (int row = 0; row < grid.length; row++) {
      if (col < grid[row].length && grid[row][col] == number) {
        return false;
      }
    }
    return true;
  }

  // Überprüft, ob eine Zahl im Dreieck zulässig ist
  bool isValidInTriangle(int row, int col, int number) {
    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;

    for (int i = startRow; i < startRow + 3; i++) {
      if (i >= grid.length) continue;
      for (int j = startCol; j < startCol + 3 && j < grid[i].length; j++) {
        if (grid[i][j] == number) {
          return false;
        }
      }
    }
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
    for (int row = 0; row < grid.length; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        if (grid[row][col] == 0) {
          for (int number = 1; number <= 9; number++) {
            if (isValidPlacement(row, col, number)) {
              grid[row][col] = number;

              if (solve()) {
                // Sobald eine Lösung gefunden wurde, speichern
                solutions.add(grid.map((row) => List<int>.from(row)).toList());
              }

              grid[row][col] = 0; // Rücksetzen (Backtracking)
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
  // Tridoku Puzzle: 1 Eintrag in der ersten Zeile, 3 in der zweiten usw.
  List<List<int>> puzzle = [
    [5],            // 1. Zeile: 1 Feld
    [0, 3, 0],      // 2. Zeile: 3 Felder
    [6, 0, 0, 7, 0], // 3. Zeile: 5 Felder
    [0, 0, 0, 0, 0, 0, 0], // 4. Zeile: 7 Felder
    [0, 0, 0, 0, 9, 0, 0, 0, 0], // 5. Zeile: 9 Felder
    [0, 0, 0, 0, 0, 0, 0], // 6. Zeile: 7 Felder
    [0, 0, 0, 6, 0], // 7. Zeile: 5 Felder
    [0, 0, 0],      // 8. Zeile: 3 Felder
    [4]             // 9. Zeile: 1 Feld
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
