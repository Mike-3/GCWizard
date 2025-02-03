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

bool solveTridokuRecursive(
    List<List<int>> grid, List<List<Set<int>>> possibleValues) {
  int row = -1;
  int col = -1;
  int minPossibleValues = 10;

  for (int i = 0; i < grid.length; i++) {
    for (int j = 0; j < grid[i].length; j++) {
      if (grid[i][j] == 0) {
        if (possibleValues[i][j].length < minPossibleValues) {
          minPossibleValues = possibleValues[i][j].length;
          row = i;
          col = j;
        }
      }
    }
  }

  if (row == -1) {
    return true; // Puzzle ist gelöst
  }

  for (int value in possibleValues[row][col]) {
    List<List<Set<int>>> possibleValuesCopy =
    possibleValues.map((row) => row.map((set) => Set<int>.from(set)).toList()).toList();

    grid[row][col] = value;
    possibleValuesCopy[row][col].clear();
    if (propagateConstraints(grid, possibleValuesCopy)) {
      if (solveTridokuRecursive(grid, possibleValuesCopy)) {
        return true;
      }
    }
    grid[row][col] = 0; // Backtracking
  }

  return false; // Keine Lösung gefunden
}

List<List<Set<int>>> initializePossibleValues(List<List<int>> grid) {
  List<List<Set<int>>> possibleValues = [];
  for (int i = 0; i < grid.length; i++) {
    possibleValues.add([]);
    for (int j = 0; j < grid[i].length; j++) {
      if (grid[i][j] == 0) {
        possibleValues[i].add({1, 2, 3, 4, 5, 6, 7, 8, 9});
      } else {
        possibleValues[i].add(<int>{}); // Leeres Set für feste Zellen
      }
    }
  }
  return possibleValues;
}

bool propagateConstraints(
    List<List<int>> grid, List<List<Set<int>>> possibleValues) {
  bool changed = true;
  while (changed) {
    changed = false;
    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[i].length; j++) {
        if (grid[i][j] == 0) {
          int originalSize = possibleValues[i][j].length;
          eliminateInvalidValues(grid, possibleValues, i, j);
          if (possibleValues[i][j].isEmpty) {
            return false; // Sackgasse
          } else if (possibleValues[i][j].length == 1) {
            grid[i][j] = possibleValues[i][j].first;
            possibleValues[i][j].clear();
            changed = true;
          } else if (possibleValues[i][j].length != originalSize) {
            changed = true;
          }
        }
      }
    }
  }
  return true;
}

void eliminateInvalidValues(
    List<List<int>> grid, List<List<Set<int>>> possibleValues, int row, int col) {
  //Eliminiere Werte aus der Reihe
  for (int i = 0; i < grid[row].length; i++) {
    possibleValues[row][col].remove(grid[row][i]);
  }

  //Eliminiere Werte aus der Spalte
  for (int i = 0; i < grid.length; i++) {
    if (col < grid[i].length) {
      possibleValues[row][col].remove(grid[i][col]);
    }
  }

  //Eliminiere Werte aus dem Block
  int blockRow = row ~/ 3;
  int blockCol = col ~/ 3;

  for (int i = 0; i < grid.length; i++) {
    for (int j = 0; j < grid[i].length; j++) {
      int currentRowBlock = i ~/ 3;
      int currentColBlock = j ~/ 3;

      if (currentRowBlock == blockRow &&
          currentColBlock == blockCol &&
          grid[i][j] != 0) {
        possibleValues[row][col].remove(grid[i][j]);
      }
    }
  }
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