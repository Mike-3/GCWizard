class Sudoku {
  List<List<int>> board;

  Sudoku(this.board);

  // bewertet den Schwierigkeitsgrad anhand leerer Felder
  String evaluate() {
    int emptyCells = board.expand((row) => row).where((cell) => cell == 0).length;
    if (emptyCells <= 28) {
      return "Pretty easy";
    } else if (emptyCells <= 39) {
      return "Easy";
    } else if (emptyCells <= 53) {
      return "Medium";
    } else if (emptyCells <= 64) {
      return "Hard";
    } else if (emptyCells <= 71) {
      return "Pretty hard";
    } else {
      return "Diabolical";
    }
  }

  void printBoard() {
    for (int i = 0; i < 9; i++) {
      print(board[i].map((x) => x != 0 ? x.toString() : ".").join(" "));
    }
  }

  bool numberIsValid(int row, int column, int number) {
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == number || board[i][column] == number) {
        return false;
      }
    }

    int startRow = (row ~/ 3) * 3;
    int startCol = (column ~/ 3) * 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (board[startRow + i][startCol + j] == number) {
          return false;
        }
      }
    }
    return true;
  }

  Stream<bool> solve() async* {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          for (int n = 1; n <= 9; n++) {
            if (numberIsValid(r, c, n)) {
              board[r][c] = n;
              yield* solve();
              board[r][c] = 0;
            }
          }
          return;
        }
      }
    }
    // Lösung gefunden, aktuelle Konfiguration yielden
    yield true;
  }
}

Future<void> main() async {
  List<List<int>> board = [
    [0, 7, 6, 0, 1, 3, 0, 0, 0],
    [0, 4, 0, 0, 0, 0, 0, 0, 0],
    [0, 0, 8, 6, 9, 0, 7, 0, 0],
    [0, 5, 0, 0, 6, 9, 0, 3, 0],
    [0, 0, 0, 0, 0, 0, 5, 4, 0],
    [0, 8, 0, 7, 3, 0, 0, 0, 0],
    [5, 1, 0, 0, 2, 6, 8, 0, 0],
    [0, 0, 7, 1, 0, 0, 9, 0, 0],
    [0, 0, 0, 0, 4, 0, 0, 6, 0]
  ];

  Sudoku sudoku = Sudoku(board);
  print("Difficulty: ${sudoku.evaluate()}");

  int counter = 0;
  await for (var _ in sudoku.solve()) {
    counter++;
    print("\nLösung $counter:");
    sudoku.printBoard();
  }

  print("\nAnzahl Lösungen: $counter");
}