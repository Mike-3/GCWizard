//https://github.com/gojkovicmatija99/Sliding-puzzle-solver
import 'dart:collection';

import 'package:gc_wizard/tools/games/sliding_puzzle/logic/astar.dart';
import 'package:gc_wizard/tools/games/sliding_puzzle/logic/state.dart';

// import 'state.dart';
// import 'algorithm.dart';
// import 'astar.dart';
// import 'main_view.dart';

// class TileByTile extends Algorithm {
//   TileByTile(State initialState, State goalState)
//       : super(initialState, goalState);
//
//   @override
  List<State> solveTileByTile(State initialState, State goalState) {
    List<State> stack = [];
    Queue<State> deque = Queue<State>();
    int numOfSteps;

    List<List<int>> initialBoard = initialState.getBoard();
    List<List<int>> goalBoard = goalState.getBoard();
    int rows = State.getRows();
    int columns = State.getColumns();
    int numOfTopRows = rows - 2;
    int numOfSorts = (columns + 1) ~/ 2;

    for (int currRow = 0; currRow <= numOfTopRows; currRow++) {
      for (int numOfTilesToSort = 1;
      numOfTilesToSort <= numOfSorts;
      numOfTilesToSort++) {
        bool twoByTwoTiles = true;
        if (currRow == numOfTopRows) {
          twoByTwoTiles = false;
        }

        int numOfBottomRows = rows - currRow;
        State.setRows(numOfBottomRows);

        List<List<int>> newInitialBoard;
        List<List<int>> newGoalBoard;
        List<List<int>> previousBoard;

        if (currRow == 0 && numOfTilesToSort == 1) {
          previousBoard = initialBoard;
        } else {
          previousBoard = deque.removeLast().getBoard();
        }

        newInitialBoard =
            getBottomHalf(previousBoard, columns, currRow, numOfBottomRows);
        newGoalBoard =
            getBottomHalf(goalBoard, columns, currRow, numOfBottomRows);

        if (twoByTwoTiles) {
          newInitialBoard = prioritizeTiles(goalBoard[currRow],
              newInitialBoard, numOfBottomRows, columns, numOfTilesToSort);
        }

        State newInitialState = State(newInitialBoard, null);
        State newGoalState = State(newGoalBoard, null);

        // AStar aStar = AStar(newInitialState, newGoalState);
        // aStar.addSubscriber(MainView.getInstance());

        stack = solveAStar(newInitialState, newGoalState);
        // numOfSteps += aStar.getNumOfSteps();
        // nodeExplored += aStar.getNodeExplored();

        addTopHalf(stack, goalBoard, rows, columns, currRow);
        addToDeque(deque, stack);
      }
    }

    return dequeToStack(deque);
  }

  List<List<int>> prioritizeTiles(List<int> pattern,
      List<List<int>> initialBoard, int rows, int columns, int limit) {
    // Alle Tiles positiv machen
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        initialBoard[i][j] = initialBoard[i][j].abs();
      }
    }

    List<List<int>> toReturn =
    List.generate(rows, (_) => List.filled(columns, 0));

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        bool contains = false;

        for (int p = 0; p < limit * 2; p++) {
          if ((p ~/ columns) == 1) continue;

          if (pattern[p] == initialBoard[i][j] ||
              initialBoard[i][j] == 0) {
            contains = true;
          }
        }

        if (contains) {
          toReturn[i][j] = initialBoard[i][j];
        } else {
          toReturn[i][j] = initialBoard[i][j] * -1;
        }
      }
    }

    return toReturn;
  }

  void addToDeque(Queue<State> deque, List<State> stack) {
    while (stack.isNotEmpty) {
      deque.addLast(stack.removeLast());
    }
  }

  List<State> dequeToStack(Queue<State> deque) {
    List<State> toReturn = [];
    while (deque.isNotEmpty) {
      toReturn.add(deque.removeLast());
    }
    return toReturn;
  }

  List<List<int>> getBottomHalf(
      List<List<int>> board,
      int columns,
      int numOfTopRows,
      int numOfBottomRows) {
    List<List<int>> toReturn =
    List.generate(numOfBottomRows, (_) => List.filled(columns, 0));

    for (int i = 0; i < numOfBottomRows; i++) {
      for (int j = 0; j < columns; j++) {
        toReturn[i][j] = board[i + numOfTopRows][j].abs();
      }
    }
    return toReturn;
  }

  void addTopHalf(List<State> stack, List<List<int>> goalBoard,
      int rows, int columns, int numOfTopRows) {
    State.setRows(rows);
    List<State> tempStack = [];

    while (stack.isNotEmpty) {
      State currState = stack.removeLast();

      List<List<int>> newBoard =
      List.generate(rows, (_) => List.filled(columns, 0));

      for (int i = 0; i < rows; i++) {
        for (int j = 0; j < columns; j++) {
          if (i < numOfTopRows) {
            newBoard[i][j] = goalBoard[i][j];
          } else {
            newBoard[i][j] =
            currState.getBoard()[i - numOfTopRows][j];
          }
        }
      }

      State newState = State(newBoard, null);
      tempStack.add(newState);
    }

    while (tempStack.isNotEmpty) {
      stack.add(tempStack.removeLast());
    }
  }
// }