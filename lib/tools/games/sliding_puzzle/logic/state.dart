import 'dart:collection';
import 'dart:math';

abstract class IHeuristic {
  int getHeuristicValue(State current, State goal);
}

class State {
  static IHeuristic? heuristic;
  static int rows = 0;
  static int columns = 0;

  State? parent;
  late List<List<int>> board;
  late Point<int> emptyField;
  int depth = 0;
  int goalDistance = 0;

  State(List<List<int>> board, this.parent) {
    emptyField = Point(0, 0);
    this.board = List.generate(
      rows,
          (_) => List.filled(columns, 0),
    );

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (board[i][j] == 0) {
          emptyField = Point(j, i);
        } else {
          this.board[i][j] = board[i][j];
        }
      }
    }
  }

  static int getRows() => rows;
  static void setRows(int value) => rows = value;

  static int getColumns() => columns;
  static void setColumns(int value) => columns = value;

  static void setHeuristic(IHeuristic h) => heuristic = h;

  void setDepth() {
    if (parent == null) {
      depth = 0;
    } else {
      depth = parent!.depth + 1;
    }
  }

  List<List<int>> getBoard() => board;

  int getGoalDistance() => goalDistance;

  void setGoalDistance(State goalState) {
    goalDistance = heuristic!.getHeuristicValue(this, goalState);
  }

  int getDepth() => depth;

  int getHeuristicValue() => goalDistance + depth;

  void setHeuristicValue(State goalState) {
    setGoalDistance(goalState);
    setDepth();
  }

  State? getParent() => parent;

  Point<int> getEmptyField() => emptyField;

  List<State> getPath() {
    State? current = this;
    final path = Queue<State>();

    while (current != null) {
      path.addFirst(current);
      current = current.parent;
    }

    return path.toList();
  }

  @override
  bool operator ==(Object other) {
    if (other is! State) return false;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (board[i][j] != other.board[i][j] &&
            (board[i][j] >= 0 && other.board[i][j] >= 0)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  int get hashCode {
    const int prime = 31;
    int result = 1;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (board[i][j] >= 0) {
          result = prime * result + board[i][j];
        } else {
          result = prime * result - 1;
        }
      }
    }

    return result;
  }
}