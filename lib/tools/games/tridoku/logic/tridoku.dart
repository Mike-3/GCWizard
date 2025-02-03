
const int gridSize = 9;

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

  // Überprüft, ob eine Zahl im Dreieck zulässig ist (z.B. in der 3x3 Box)
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

  // Der Backtracking-Algorithmus zur Lösung des Tridoku
  bool solve() {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        if (grid[row][col] == 0) {
          for (int number = 1; number <= 9; number++) {
            if (isValidPlacement(row, col, number)) {
              grid[row][col] = number;

              if (solve()) {
                return true;
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

  // Druckt das Tridoku-Gitter
  void printGrid() {
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        print('${grid[row][col]} ');
      }
      print('\n');
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

  if (solver.solve()) {
    print('Tridoku gelöst:');
    solver.printGrid();
  } else {
    print('Keine Lösung möglich');
  }
}
