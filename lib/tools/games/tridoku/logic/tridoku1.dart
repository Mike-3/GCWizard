

const int gridSize = 9;
List<List<List<int>>> solutions = [];

class TridokuSolver {
  List<List<int>> grid;

  TridokuSolver(this.grid);

  // Überprüft, ob eine Zahl in der Zeile zulässig ist
  bool isValidInRow(int row, int number) {
    for (int col = 0; col < gridSize; col++) {
      if (grid[row][col] == number) {
        return false;
      }
    }
    return true;
  }

  // Überprüft, ob eine Zahl in der Spalte zulässig ist
  bool isValidInCol(int col, int number) {
    for (int row = 0; row < gridSize; row++) {
      if (grid[row][col] == number) {
        return false;
      }
    }
    return true;
  }

  // Überprüft, ob eine Zahl im Dreieck zulässig ist (z.B. in der dreieckigen Box)
  bool isValidInTriangle(int row, int col, int number) {
    int startRow = (row ~/ 3) * 3;
    int startCol = (col ~/ 3) * 3;

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (grid[startRow + i][startCol + j] == number) {
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
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (grid[row][col] == 0) {
          for (int number = 1; number <= 9; number++) {
            if (isValidPlacement(row, col, number)) {
              grid[row][col] = number;

              if (solve()) {
                // Sobald eine Lösung gefunden wurde, speichern
                solutions.add(List.from(grid.map((row) => List<int>.from(row))));
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
  void printTriangleGrid() {
    for (int row = 0; row < gridSize; row++) {
      // Einrücken für die dreieckige Darstellung
      String indent = ' ' * (gridSize - row);
      print(indent + grid[row].join(' '));
    }
  }
}

void main() {
  List<List<int>> puzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9]
  ];

  TridokuSolver solver = TridokuSolver(puzzle);

  solver.solve();

  if (solutions.isNotEmpty) {
    print('Es wurden ${solutions.length} Lösungen gefunden:');
    solver.printTriangleGrid();
    print('\n');
    for (var solution in solutions) {
      for (var row in solution) {
        print(row.join(' '));
      }
      print('\n');
    }
  } else {
    print('Keine Lösung möglich');
  }
}
