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

  // Überprüfe Spalte (korrigiert)
  for (int i = 0; i < grid.length; i++) {
    if (col < grid[i].length && grid[i][col] == number) return false;
  }

  // Überprüfe Block (korrigiert und vereinfacht)
  int blockRow = row ~/ 3;
  int blockCol = col ~/ 3;

  for (int i = 0; i < grid.length; i++){
    for (int j = 0; j < grid[i].length; j++){
      int currentRowBlock = i ~/ 3;
      int currentColBlock = j ~/ 3;

      if (currentRowBlock == blockRow && currentColBlock == blockCol && grid[i][j] == number){
        return false;
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