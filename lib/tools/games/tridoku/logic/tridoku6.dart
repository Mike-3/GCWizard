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
  int row = -1;
  int col = -1;
  bool isEmpty = true;
  for (int i = 0; i < grid.length; i++) {
    for (int j = 0; j < grid[i].length; j++) {
      if (grid[i][j] == 0) {
        row = i;
        col = j;
        isEmpty = false;
        break;
      }
    }
    if (!isEmpty) {
      break;
    }
  }

  if (isEmpty) {
    return true; // Puzzle ist gelöst
  }

  for (int number = 1; number <= 9; number++) {
    if (isValid(grid, row, col, number)) {
      grid[row][col] = number;
      if (solveTridoku(grid)) {
        return true; // Lösung gefunden
      } else {
        grid[row][col] = 0; // Backtracking: Zahl zurücksetzen
      }
    }
  }
  return false; // Keine Lösung gefunden
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

  // Überprüfe Block (korrigiert)
  int blockRowStart = (row ~/ 3) * 3;
  int blockColStart = (col ~/ 3) * 3;

  for (int i = blockRowStart; i < blockRowStart + 3; i++) {
    if (i < grid.length) {
      int blockColEnd = blockColStart + 3;
      if (blockColEnd > grid[i].length) {
        blockColEnd = grid[i].length;
      }
      for (int j = blockColStart; j < blockColEnd; j++) {
        if (grid[i][j] == number) {
          return false;
        }
      }
    }
  }

  return true;
}

void printGrid(List<List<int>> grid) {
  for (var row in grid) {
    print(row);
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