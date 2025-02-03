List<List<int>> puzzle = [
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

bool solveTridoku(List<List<int>> grid) {
  List<List<Set<int>>> possibleValues = initializePossibleValues(grid);

  if (!propagateConstraints(grid, possibleValues)) {
    return false; // Keine Lösung gefunden
  }

  return solveTridokuRecursive(grid, possibleValues);
}

bool isValid(List<List<int>> grid, int row, int col, int number) {
  // Überprüfe Reihe
  for (int i = 0; i < grid[row].length; i++) {
    if (grid[row][i] == number) return false;
  }

  // Überprüfe Spalte
  for (int i = 0; i < grid.length; i++) {
    if (col < grid[i].length && grid[i][col] == number) return false;
  }

  // Überprüfe Block
  int blockRow = row ~/ 3;
  int blockCol = col ~/ 3;

  for (int i = 0; i < grid.length; i++) {
    for (int j = 0; j < grid[i].length; j++) {
      int currentRowBlock = i ~/ 3;
      int currentColBlock = j ~/ 3;

      if (currentRowBlock == blockRow &&
          currentColBlock == blockCol &&
          grid[i][j] == number) {
        return false;
      }
    }
  }

  // Überprüfe äußere Konturen (neu)
  if (row == 0 || row == grid.length - 1 || col == 0 || col == grid[row].length - 1) {
    for (int i = 0; i < grid.length; i++) {
      if (i != row && i < grid.length && col < grid[i].length && grid[i][col] == number) {
        return false;
      }
      for (int j = 0; j < grid[i].length; j++) {
        if ((j == 0 || j == grid[i].length - 1) && (i == 0 || i == grid.length - 1) && i != row && grid[i][j] == number){
          return false;
        }
      }
    }
  }

  return true;
}

void printGrid(List<List<int>> grid) {
  for (int row = 0; row < grid.length; row++) {
    // Einrücken für die dreieckige Darstellung
    String indent = '  ' * (grid.length - row - 1);
    print(indent + grid[row].map((val) => val.toString()).join(' '));
  }
}

void main() {
  if (solveTridoku(puzzle)) {
    print("Tridoku gelöst:");
    printGrid(puzzle);
  } else {
    print("Keine Lösung gefunden.");
  }
}