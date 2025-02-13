class Tridoku {
  static const int size = 9; // Number of rows in the Tridoku grid
  List<List<int>> grid;

  Tridoku(List<List<int>> initialGrid) : grid = initialGrid;

  // Check if a number can be placed in a specific cell
  bool isSafe(int row, int col, int num) {
    // Check the row for duplicates
    for (int i = 0; i < grid[row].length; i++) {
      if (grid[row][i] == num) {
        return false;
      }
    }

    // Check the column for duplicates
    for (int i = 0; i < size; i++) {
      if (i < grid.length && col < grid[i].length && grid[i][col] == num) {
        return false;
      }
    }

    // Check the diagonals for duplicates
    // Diagonal 1: Top-left to bottom-right
    if (row == col) {
      for (int i = 0; i < size; i++) {
        if (i < grid.length && i < grid[i].length && grid[i][i] == num) {
          return false;
        }
      }
    }

    // Diagonal 2: Top-right to bottom-left
    if (row + col == grid.length - 1) {
      for (int i = 0; i < size; i++) {
        if (i < grid.length && (grid.length - 1 - i) < grid[i].length && grid[i][grid.length - 1 - i] == num) {
          return false;
        }
      }
    }

    return true;
  }

  // Solve the Tridoku using backtracking
  bool solve() {
    for (int row = 0; row < size; row++) {
      for (int col = 0; col < grid[row].length; col++) {
        if (grid[row][col] == 0) {
          for (int num = 1; num <= 9; num++) {
            if (isSafe(row, col, num)) {
              grid[row][col] = num;

              if (solve()) {
                return true;
              }

              grid[row][col] = 0; // Backtrack
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  // Print the Tridoku grid
  void printGrid() {
    for (int row = 0; row < size; row++) {
      // Add leading spaces for triangular formatting
      print(' ' * (size - row - 1) + grid[row].join(' '));
    }
  }
}

void main() {
  // Initialize the Tridoku grid with 0s representing empty cells
  List<List<int>> initialGrid = [
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

  Tridoku tridoku = Tridoku(initialGrid);

  if (tridoku.solve()) {
    print("Solution found:");
    tridoku.printGrid();
  } else {
    print("No solution exists.");
  }
}