import 'dart:math';

class GameOfLifeData {
  late List<List<List<bool>>> boards;
  List<List<bool>> currentBoard = [];
  var step = 0;
  final Point<int> size;

  GameOfLifeData(this.size, {List<List<bool>>? content}) {
    _generateBoard(content);
  }

  void _generateBoard(List<List<bool>>? content) {
    var _newBoard = List<List<bool>>.generate(size.y, (index) => List<bool>.generate(size.x, (index) => false));

    if (content != null && content.isNotEmpty) {
      for (int i = 0; i < min(size.y, content.length); i++) {
        for (int j = 0; j < min(size.x, content[i].length); j++) {
          _newBoard[i][j] = content[i][j];
        }
      }
    }

    boards = <List<List<bool>>>[];
    boards.add(_newBoard);

    currentBoard = List.from(_newBoard);
    step = 0;
  }

  void reset({List<List<bool>>? board}) {
    boards = <List<List<bool>>>[];
    boards.add(board ?? List.from(currentBoard));

    step = 0;
  }

  int _countNeighbors(List<List<bool>> board, int i, int j, {bool isOpenWorld = false}) {
    var counter = 0;

    for (int k = i - 1; k <= i + 1; k++) {
      if (!isOpenWorld && (k < 0 || k == size.y)) continue;

      for (int l = j - 1; l <= j + 1; l++) {
        if (!isOpenWorld && (l < 0 || l == size.x)) continue;

        if (k == i && l == j) continue;

        if (board[k % size.y][l % size.x]) {
          counter++;
        }
      }
    }

    return counter;
  }

  List<List<bool>> calculateStep(List<List<bool>> board, GameOfLifeRules rules, {bool isWrapWorld = false}) {
    var _newStepBoard = List<List<bool>>.generate(size.y, (index) => List<bool>.generate(size.x, (index) => false));

    var _rules = rules;
    if (_rules.isInverse) {
      _rules = rules.inverseRules();
    } else {
      _rules = rules;
    }

    for (int i = 0; i < size.y; i++) {
      for (int j = 0; j < size.x; j++) {
        var countNeighbors = _countNeighbors(board, i, j, isOpenWorld: isWrapWorld);
        if (board[i][j] && _rules.survivals.contains(countNeighbors)) {
          _newStepBoard[i][j] = true;
        }
        if (!board[i][j] && _rules.births.contains(countNeighbors)) {
          _newStepBoard[i][j] = true;
        }
      }
    }

    return _newStepBoard;
  }
}


class GameOfLifeRules {
  final Set<int> survivals;
  final Set<int> births;
  final bool isInverse;

  const GameOfLifeRules({this.survivals = const {}, this.births = const {}, this.isInverse = false});

  GameOfLifeRules inverseRules() {
    var inverseSurvivals = <int>{};
    var inverseBirths = <int>{};

    var deaths = <int>{};

    for (int i = 0; i <= 8; i++) {
      if (survivals.contains(i)) continue;

      deaths.add(i);
    }

    var inverseDeaths = births.map((e) => 8 - e).toSet();
    inverseBirths = deaths.map((e) => 8 - e).toSet();

    for (int i = 0; i <= 8; i++) {
      if (inverseDeaths.contains(i)) continue;

      inverseSurvivals.add(i);
    }

    return GameOfLifeRules(survivals: inverseSurvivals, births: inverseBirths);
  }
}

const Map<String, GameOfLifeRules> DEFAULT_GAME_OF_LIFE_RULES = {
  'gameoflife_conway': GameOfLifeRules(survivals: {2, 3}, births: {3}),
  'gameoflife_copy': GameOfLifeRules(survivals: {1, 3, 5, 7}, births: {1, 3, 5, 7}),
  'gameoflife_3_3': GameOfLifeRules(survivals: {3}, births: {3}),
  'gameoflife_13_3': GameOfLifeRules(survivals: {1, 3}, births: {3}),
  'gameoflife_34_3': GameOfLifeRules(survivals: {3, 4}, births: {3}),
  'gameoflife_35_3': GameOfLifeRules(survivals: {3, 5}, births: {3}),
  'gameoflife_2_3': GameOfLifeRules(survivals: {2}, births: {3}),
  'gameoflife_24_3': GameOfLifeRules(survivals: {2, 4}, births: {3}),
  'gameoflife_245_3': GameOfLifeRules(survivals: {2, 4, 5}, births: {3}),
  'gameoflife_125_36': GameOfLifeRules(survivals: {1, 2, 5}, births: {3, 6}),
  'gameoflife_inverseconway': GameOfLifeRules(survivals: {2, 3}, births: {3}, isInverse: true),
  'gameoflife_inversecopy': GameOfLifeRules(survivals: {1, 3, 5, 7}, births: {1, 3, 5, 7}, isInverse: true),
};


