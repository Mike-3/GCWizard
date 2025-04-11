import 'dart:math';

class Sudoku {
  List<List<int>> board;

  Sudoku(this.board);

  final List<List<Point<int>>> _unitlist = [
    <Point<int>>[Point<int>(0,0), Point<int>(1,0), Point<int>(2,0), Point<int>(3,0), Point<int>(4,0), Point<int>(5,0), Point<int>(6,0), Point<int>(7,0), Point<int>(8,0)], // outer sides
     <Point<int>>[Point<int>(8,0), Point<int>(8,2), Point<int>(8,4), Point<int>(8,6), Point<int>(8,8), Point<int>(8,10), Point<int>(8,12), Point<int>(8,14), Point<int>(8,16)],
  <Point<int>>[Point<int>(0,0), Point<int>(1,2), Point<int>(2,4), Point<int>(3,6), Point<int>(4,8), Point<int>(5,10), Point<int>(6,12), Point<int>(7,14), Point<int>(8,16)],
  <Point<int>>[Point<int>(4,0), Point<int>(4,1), Point<int>(4,2), Point<int>(4,3), Point<int>(4,4), Point<int>(4,5), Point<int>(4,6), Point<int>(4,7), Point<int>(4,8)], // inner triangles
  <Point<int>>[Point<int>(4,0), Point<int>(5,1), Point<int>(5,2), Point<int>(6,3), Point<int>(6,4), Point<int>(7,5), Point<int>(7,6), Point<int>(8,7), Point<int>(8,8)],
  <Point<int>>[Point<int>(4,8), Point<int>(5,8), Point<int>(5,9), Point<int>(6,8), Point<int>(6,9), Point<int>(7,8), Point<int>(7,9), Point<int>(8,8), Point<int>(8,9)],
  <Point<int>>[Point<int>(0,0), Point<int>(1,0), Point<int>(1,1), Point<int>(1,2), Point<int>(2,0), Point<int>(2,1), Point<int>(2,2), Point<int>(2,3), Point<int>(2,4)], // triangle
  <Point<int>>[Point<int>(3,0), Point<int>(4,0), Point<int>(4,1), Point<int>(4,2), Point<int>(5,0), Point<int>(5,1), Point<int>(5,2), Point<int>(5,3), Point<int>(5,4)],
  <Point<int>>[Point<int>(6,0), Point<int>(7,0), Point<int>(7,1), Point<int>(7,2), Point<int>(8,0), Point<int>(8,1), Point<int>(8,2), Point<int>(8,3), Point<int>(8,4)],
  <Point<int>>[Point<int>(3,6), Point<int>(4,6), Point<int>(4,7), Point<int>(4,8), Point<int>(5,6), Point<int>(5,7), Point<int>(5,8), Point<int>(5,9), Point<int>(5,10)],
  <Point<int>>[Point<int>(6,12), Point<int>(7,12), Point<int>(7,13), Point<int>(7,14), Point<int>(8,12), Point<int>(8,13), Point<int>(8,14), Point<int>(8,15), Point<int>(8,16)],
  <Point<int>>[Point<int>(6,6), Point<int>(7,6), Point<int>(7,7), Point<int>(7,8), Point<int>(8,6), Point<int>(8,7), Point<int>(8,8), Point<int>(8,9), Point<int>(8,10)],
  <Point<int>>[Point<int>(3,1), Point<int>(3,2), Point<int>(3,3), Point<int>(3,4), Point<int>(3,5), Point<int>(4,3), Point<int>(4,4), Point<int>(4,5), Point<int>(5,5)],
  <Point<int>>[Point<int>(6,1), Point<int>(6,2), Point<int>(6,3), Point<int>(6,4), Point<int>(6,5), Point<int>(7,3), Point<int>(7,4), Point<int>(7,5), Point<int>(8,5)],
  <Point<int>>[Point<int>(6,7), Point<int>(6,8), Point<int>(6,9), Point<int>(6,10), Point<int>(6,11), Point<int>(7,9), Point<int>(7,10), Point<int>(7,11), Point<int>(8,11)],
 // <Point<int>>[Point<int>(1,0), Point<int>(1,1), Point<int>(1,2), Point<int>(2,1), Point<int>(2,2), Point<int>(2,3)], // Hexagons
 //    <Point<int>>[Point<int>(2,0), Point<int>(2,1), Point<int>(2,2), Point<int>(3,1), Point<int>(3,2), Point<int>(3,3)],
 //    <Point<int>>[Point<int>(2,2), Point<int>(2,3), Point<int>(2,4), Point<int>(3,3), Point<int>(3,4), Point<int>(3,5)],
 // <Point<int>>[Point<int>(3,0), Point<int>(3,1), Point<int>(3,2), Point<int>(4,1), Point<int>(4,2), Point<int>(4,3)],
 // <Point<int>>[Point<int>(3,2), Point<int>(3,3), Point<int>(3,4), Point<int>(4,3), Point<int>(4,4), Point<int>(4,5)],
 // <Point<int>>[Point<int>(3,4), Point<int>(3,5), Point<int>(3,6), Point<int>(4,5), Point<int>(4,6), Point<int>(4,7)],
 // <Point<int>>[Point<int>(5,0), Point<int>(5,1), Point<int>(5,2), Point<int>(6,1), Point<int>(6,2), Point<int>(6,3)],
 // <Point<int>>[Point<int>(5,2), Point<int>(5,3), Point<int>(5,4), Point<int>(6,3), Point<int>(6,4), Point<int>(6,5)],
 // <Point<int>>[Point<int>(5,4), Point<int>(5,5), Point<int>(5,6), Point<int>(6,5), Point<int>(6,6), Point<int>(6,7)],
 // <Point<int>>[Point<int>(5,6), Point<int>(5,7), Point<int>(5,8), Point<int>(6,7), Point<int>(6,8), Point<int>(6,9)],
 // <Point<int>>[Point<int>(5,8), Point<int>(5,9), Point<int>(5,10), Point<int>(6,9), Point<int>(6,10), Point<int>(6,11)],
 // <Point<int>>[Point<int>(7,0), Point<int>(7,1), Point<int>(7,2), Point<int>(8,1), Point<int>(8,2), Point<int>(8,3)],
 // <Point<int>>[Point<int>(7,2), Point<int>(7,3), Point<int>(7,4), Point<int>(8,3), Point<int>(8,4), Point<int>(8,5)],
 // <Point<int>>[Point<int>(7,4), Point<int>(7,5), Point<int>(7,6), Point<int>(8,5), Point<int>(8,6), Point<int>(8,7)],
 // <Point<int>>[Point<int>(7,6), Point<int>(7,7), Point<int>(7,8), Point<int>(8,7), Point<int>(8,8), Point<int>(8,9)],
 // <Point<int>>[Point<int>(7,8), Point<int>(7,9), Point<int>(7,10), Point<int>(8,9), Point<int>(8,10), Point<int>(8,11)],
 // <Point<int>>[Point<int>(7,10), Point<int>(7,11), Point<int>(7,12), Point<int>(8,11), Point<int>(8,12), Point<int>(8,13)],
 // <Point<int>>[Point<int>(7,12), Point<int>(7,13), Point<int>(7,14), Point<int>(8,13), Point<int>(8,14), Point<int>(8,15)],
    ];

  void printBoard() {
    for (int i = 0; i < 9; i++) {
      print(board[i].map((x) => x != 0 ? x.toString() : ".").join(" "));
    }
  }

  int _columnCount(int row) => (row * 2) + 1;

  List<List<Point<int>>> hexagons(int row, int column) {
    final lists = <List<Point<int>>>[];

    void addCells(List<List<int>> coords) {
      final list = <Point<int>>[];
      for (final [r, c] in coords) {
        if (r > 0 && r < 9 && c > 0 && c < _columnCount(r)) {
          list.add(Point<int>(r, c));
        }
      }
      if (list.length > 1) {
        lists.add(list);
        print('row: $row column: $column ' + list.toString());
      }
    }

    addCells([
      for (int c = column - 3; c < column - 1; c++) [row - 1, c],
      for (int c = column - 2; c <= column; c++) [row, c],
    ]);

    addCells([
      for (int c = column - 1; c < column + 1; c++) [row - 1, c],
      for (int c = column; c <= column + 2; c++) [row, c],
    ]);

    addCells([
      for (int c = column - 1; c < column + 1; c++) [row, c],
      for (int c = column; c <= column + 2; c++) [row + 1, c],
    ]);

    return lists;
  }

  bool numberIsValid(int row, int column, int number) {
    final point = Point<int>(row, column);
    final unitLists = [
      ..._unitlist.where((list) => list.contains(point)),
      ...hexagons(row, column),
    ];

    return unitLists.every((list) =>
        list.every((p) => board[p.x][p.y] != number));
  }

  // bool numberIsValid(int row, int column, int number) {
  //   // _unitlist.where((pList) => pList.contains(Point<int>(row, column))).forEach((pList) {
  //   //   if (pList.any((point) => board[point.y][point.x]  == number)) return false;
  //   // });
  //   // printBoard();
  //   var lists = _unitlist.where((pList) => pList.contains(Point<int>(row, column)));
  //   for (var pList in lists) {
  //      // print(pList.toString());
  //     if (pList.any((point) => board[point.x][point.y] == number)) return false;
  //     // if (pList.any((point) {
  //     //   // print(point.toString() + ' ' + board[point.x].length.toString());
  //     //   return board[point.x][point.y] == number;
  //     // })) {
  //     //   return false;
  //     // }
  //   }
  //   lists = hexagons(row, column);
  //   for (var pList in lists) {
  //     if (pList.any((point) => board[point.x][point.y] == number)) return false;
  //   }
  //   return true;
  // }

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
  List<List<int>> board = [ //https://logic-masters.de/Raetselportal/Raetsel/zeigen.php?chlang=en&id=000DEM
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