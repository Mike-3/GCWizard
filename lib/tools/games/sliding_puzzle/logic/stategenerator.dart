import 'dart:math';

import 'state.dart';
// Kleine Verbesserungsidee (optional)
//
// Du erzeugst bei jeder Bewegung ein komplett neues Board → korrekt, aber teuer.
//
// Später könntest du:
//
// Board klonen mit .map()
// oder sogar immutable states + caching
class StateGenerator {
  static State makeGoalState() {
    int rows = State.getRows();
    int columns = State.getColumns();

    int num = 1;
    List<List<int>> goalBoard =
    List.generate(rows, (_) => List.filled(columns, 0));

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (i == rows - 1 && j == columns - 1) {
          goalBoard[i][j] = 0;
        } else {
          goalBoard[i][j] = num++;
        }
      }
    }

    return State(goalBoard, null);
  }

  List<State> generateStates(State currentState) {
    Point<int> emptyField = currentState.getEmptyField();
    State parent = currentState;
    int rows = State.getRows();
    int columns = State.getColumns();

    List<State> nextStates = [];

    if (checkRight(emptyField, columns)) {
      nextStates.add(moveRight(rows, columns, emptyField, parent));
    }
    if (checkDown(emptyField, rows)) {
      nextStates.add(moveDown(rows, columns, emptyField, parent));
    }
    if (checkUp(emptyField)) {
      nextStates.add(moveUp(rows, columns, emptyField, parent));
    }
    if (checkLeft(emptyField, columns)) {
      nextStates.add(moveLeft(rows, columns, emptyField, parent));
    }

    return nextStates;
  }

  bool checkUp(Point<int> emptyField) {
    int pos = emptyField.y - 1;
    return pos >= 0;
  }

  bool checkDown(Point<int> emptyField, int rows) {
    int pos = emptyField.y + 1;
    return pos < rows;
  }

  bool checkLeft(Point<int> emptyField, int columns) {
    return emptyField.x % columns != 0;
  }

  bool checkRight(Point<int> emptyField, int columns) {
    return emptyField.x % columns != columns - 1;
  }

  State moveUp(int rows, int columns, Point<int> emptyField, State parent) {
    List<List<int>> newBoard =
    List.generate(rows, (_) => List.filled(columns, 0));

    copyBoard(newBoard, rows, columns, parent);

    int temp = newBoard[emptyField.y][emptyField.x];
    newBoard[emptyField.y][emptyField.x] =
    newBoard[emptyField.y - 1][emptyField.x];
    newBoard[emptyField.y - 1][emptyField.x] = temp;

    return State(newBoard, parent);
  }

  State moveDown(int rows, int columns, Point<int> emptyField, State parent) {
    List<List<int>> newBoard =
    List.generate(rows, (_) => List.filled(columns, 0));

    copyBoard(newBoard, rows, columns, parent);

    int temp = newBoard[emptyField.y][emptyField.x];
    newBoard[emptyField.y][emptyField.x] =
    newBoard[emptyField.y + 1][emptyField.x];
    newBoard[emptyField.y + 1][emptyField.x] = temp;

    return State(newBoard, parent);
  }

  State moveLeft(int rows, int columns, Point<int> emptyField, State parent) {
    List<List<int>> newBoard =
    List.generate(rows, (_) => List.filled(columns, 0));

    copyBoard(newBoard, rows, columns, parent);

    int temp = newBoard[emptyField.y][emptyField.x];
    newBoard[emptyField.y][emptyField.x] =
    newBoard[emptyField.y][emptyField.x - 1];
    newBoard[emptyField.y][emptyField.x - 1] = temp;

    return State(newBoard, parent);
  }

  State moveRight(int rows, int columns, Point<int> emptyField, State parent) {
    List<List<int>> newBoard =
    List.generate(rows, (_) => List.filled(columns, 0));

    copyBoard(newBoard, rows, columns, parent);

    int temp = newBoard[emptyField.y][emptyField.x];
    newBoard[emptyField.y][emptyField.x] =
    newBoard[emptyField.y][emptyField.x + 1];
    newBoard[emptyField.y][emptyField.x + 1] = temp;

    return State(newBoard, parent);
  }

  void copyBoard(List<List<int>> newBoard, int rows, int columns, State parent) {
    List<List<int>> board = parent.getBoard();

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        newBoard[i][j] = board[i][j];
      }
    }
  }
}