import 'dart:collection';

// import 'algorithm.dart';
import 'package:collection/collection.dart';

import 'state.dart';
// import 'state_comparator.dart';
// import 'state_generator.dart';

// class AStar extends Algorithm {
//   AStar(State initialState, State goalState)
//       : super(initialState, goalState);
//
//   @override
  List<State> solveAStar(State initialState, State goalState) {
    int nodeExploredLocal = 0;
    List<State> toReturn = [];

    // PriorityQueue Ersatz in Dart
    final queue = PriorityQueue<State>(
          (a, b) => StateComparator().compare(a, b),
    );

    final Set<State> visited = {};
    final generator = StateGenerator();

    queue.add(initialState);
    visited.add(initialState);

    while (queue.isNotEmpty) {
      nodeExploredLocal++;

      // Update alle 100000 Knoten
      // if (nodeExploredLocal % 100000 == 0) {
      //   notifySubscriber(nodeExploredLocal);
      // }

      State current = queue.removeFirst();

      if (current == goalState) {
        // numOfSteps = current.getDepth();
        // nodeExplored = nodeExploredLocal;
        toReturn = current.getPath();
        return toReturn;
      }

      List<State> nextStates = generator.generateStates(current);

      for (State state in nextStates) {
        state.setHeuristicValue(goalState);

        if (!visited.contains(state)) {
          queue.add(state);
          visited.add(state);
        }
      }
    }

    return toReturn;
  }
// }