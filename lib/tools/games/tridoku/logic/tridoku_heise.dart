class Sudoku {
  List<List<int>> board;

  Sudoku(this.board);

  void printBoard() {
    for (int i = 0; i < 9; i++) {
      print(board[i].map((x) => x != 0 ? x.toString() : ".").join(" "));
    }
  }

  int _columnCount(int row) => (row * 2) + 1;

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
      for (int c = 0; c < _columnCount(r); c++) {
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
    [6],
    [0, 0, 4],
    [0, 2, 0, 8, 0],
    [0, 0, 3, 0, 7, 2, 1],
    [0, 0, 1, 0, 0, 0, 0, 5, 0],
    [0, 0, 0, 0, 2, 0, 0, 0, 8, 0, 3],
    [0, 6, 0, 0, 5, 0, 0, 3, 0, 0, 7, 0, 8],
    [0, 0, 5, 3, 7, 0, 0, 1, 0, 0, 6, 5, 4, 0, 0],
    [0, 1, 0, 4, 0, 0, 0, 6, 0, 0, 4, 0, 2, 0, 0, 3, 0],
  ];

  Sudoku sudoku = Sudoku(board);

  int counter = 0;
  await for (var _ in sudoku.solve()) {
    counter++;
    print("\nLösung $counter:");
    sudoku.printBoard();
  }

  print("\nAnzahl Lösungen: $counter");
}