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

  while (true) {
    bool changed = false;
    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[i].length; j++) {
        if (grid[i][j] == 0) {
          int originalSize = possibleValues[i][j].length;
          eliminateInvalidValues(grid, possibleValues, i, j);
          if (possibleValues[i][j].length == 1) {
            grid[i][j] = possibleValues[i][j].first;
            possibleValues[i][j].clear(); // Zelle ist nun fixiert
            changed = true;
          } else if (possibleValues[i][j].length != originalSize) {
            changed = true;
          }
        }
      }
    }
    if (!changed) break; // Keine Änderungen mehr möglich
  }

  // Überprüfen, ob das Puzzle gelöst ist
  for (int i = 0; i < grid.length; i++) {
    for (int j = 0; j < grid[i].length; j++) {
      if (grid[i][j] == 0) return false; // Puzzle ist nicht gelöst
    }
  }
  return true; // Puzzle ist gelöst
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