

import 'package:gc_wizard/tools/games/sliding_puzzle/logic/state.dart';

class Hamming implements IHeuristic {
  @override
  int getHeuristicValue(State initialState, State goalState) {
    int rows = State.getRows();
    int columns = State.getColumns();

    List<List<int>> initialBoard = initialState.getBoard();
    List<List<int>> goalBoard = goalState.getBoard();

    int diff = 0;

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (initialBoard[i][j] == 0 || initialBoard[i][j] < 0) continue;

        if (initialBoard[i][j] != goalBoard[i][j]) {
          diff++;
        }
      }
    }

    return diff;
  }
}