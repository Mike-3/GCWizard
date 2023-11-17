/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
// package com.dosse.tetrisPuzzleSolver;
//
// import java.io.DataInputStream;
// import java.io.DataOutputStream;
// import java.io.IOException;
// import java.io.InputStream;
// import java.io.OutputStream;
// import java.util.LinkedList;

import 'dart:math';


/**
 * Fills a box with tetris shapes (tetraminos). Implemented to solve annoying
 * tetris puzzles found in The Talos Principle. This is the Multithread version
 * of the algorithm.
 *
 * @author Federico
 */
class TetrisPuzzleSolverMT {

  static const String I = 'i', O = 'o', T = 't', J = 'j', L = 'l', S = 's', Z = 'z';

  late final List<String> _blocks; //blocks to add

  final _queue = <BoardState>[]; //this contains all the work units. work units are added and removed by SlaveThreads
  //int iterations = 0; //number of processed work units

  bool stopASAP = false; //set to true to cancel computation
  bool paused = false, masterPaused = true; //used by save/load methods. setting paused to true causes all threads to stop as soon as possible in a safe state. masterPaused is set to true by the master thread when it's paused in a safe state

  late List<SlaveThread> _slaves; //[Runtime.getRuntime().availableProcessors()]; //1 slave thread per core (+1 master thread)

  //initialize slaves (without actually starting them)
  // {
  //     for (int i = 0; i < slaves.length; i++) {
  //         slaves[i] = new SlaveThread();
  //     }
  // }

  late int _w, _h; //cols and rows of the board

  /**
   * create a new solver. call solve() to actually start solving.
   *
   * @param width columns
   * @param height rows
   * @param iBlocks number of I blocks
   * @param oBlocks number of O blocks
   * @param tBlocks number of T blocks
   * @param jBlocks number of J blocks
   * @param lBlocks number of L blocks
   * @param sBlocks number of S blocks
   * @param zBlocks number of Z blocks
   */
  TetrisPuzzleSolverMT(int width, int height, int iBlocks, int oBlocks, int tBlocks, int jBlocks, int lBlocks, int sBlocks, int zBlocks) {
    _w = width;
    _h = height;
    int nBlocks = iBlocks + oBlocks + tBlocks + jBlocks + lBlocks + sBlocks + zBlocks;
    _blocks = List<String>.filled(nBlocks, '');
    _slaves = List<SlaveThread>.generate(4, (i) => SlaveThread(_blocks, _queue, i)); //

    int p = 0;
    for (int i = 0; i < iBlocks; i++) {
      _blocks[p++] = I;
    }
    for (int i = 0; i < oBlocks; i++) {
      _blocks[p++] = O;
    }
    for (int i = 0; i < tBlocks; i++) {
      _blocks[p++] = T;
    }
    for (int i = 0; i < jBlocks; i++) {
      _blocks[p++] = J;
    }
    for (int i = 0; i < lBlocks; i++) {
      _blocks[p++] = L;
    }
    for (int i = 0; i < sBlocks; i++) {
      _blocks[p++] = S;
    }
    for (int i = 0; i < zBlocks; i++) {
      _blocks[p++] = Z;
    }
    //scramble blocks. seems to lead to a solution faster
    for(int i = 0; i < nBlocks; i++){
      int r = (Random().nextDouble()*nBlocks).toInt();
      int r2 = (Random().nextDouble()*nBlocks).toInt();
      var temp = _blocks[r];
      _blocks[r] = _blocks[r2];
      _blocks[r2] = temp;
    }
    if (nBlocks * 4 != width * height) {
      solved = true;
      cachedResult = null;
      return;
    }
    //create and add the first work unit, initially empty.
    var s = BoardState._create(width, height);
    _queue.add(s);
  }

  /**
   *
   * @return columns
   */
  int getWidth() {
    return _w;
  }

  /**
   *
   * @return rows
   */
  int getHeight() {
    return _h;
  }

  /**
   *
   * @return number of pieces
   */
  int getNumberOfPieces() {
    return _blocks.length;
  }

  /**
   *
   * @return true if the puzzle has been solved (even if it has no solution)
   * (in other words, if the solve() method was called and has finished or was
   * canceled)
   */
  bool isSolved() {
    return solved;
  }
  
  bool solved = false; //set to indicate that the solve() method has been called and has finished processing (or was canceled)
  _Solution? cachedResult; //the result of the solve() method so it doesn't need to be calculated again. null if no solution was found (or solve() was canceled)

  /**
   * solve the puzzle. blocking. use cancel() to stop solving
   *
   * @return an instance of Solution if the puzzle has a solution, null if it
   * doesn't (or if cancel() was called)
   */
  Future<_Solution?> solve() async {
    if (solved) { //already solved
      return cachedResult!;
    }
    masterPaused = false;
    //set current thread as master
    // int oldPriority = Thread.currentThread().getPriority();
    // Thread.currentThread().setPriority(Thread.NORM_PRIORITY);
    // String oldName = Thread.currentThread().getName();
    // Thread.currentThread().setName("TPS_MASTER");
    _Solution? ret; //this will contain the return value (Solution or null)
    //start slaves
    for (SlaveThread s in _slaves) {
      s.run(); //Isolate.run( s.run);
      // if (sol != null) {
      //   sol =sol;
      // }
    }
    //force a context switch so they actually start. cheap, I know.
    // try {
    //   Thread.sleep(1);
    // } catch (InterruptedException ex) {
    // }
    for (;;) {
      //safe state for pausing
      if (paused) {
        while (paused) {
          masterPaused = true;
          // try {
          // Thread.sleep(100);
          // } catch (InterruptedException ex) {
          // }
        }
      }
      masterPaused = false;
      //safe state for cancel()
      if (stopASAP) {
        break;
      }
      //avoid busy waiting
      // try {
      // Thread.sleep(1);
      // } catch (InterruptedException ex) {
      // }
      //check if a slave has solved the puzzle
      bool done = false;
      for (SlaveThread s in _slaves) {
        if (s.solution != null) {
          ret = s.solution;
          done = true;
          break;
        }
      }
      if (done) {
        break;
      }
      //check if all slaves are waiting and the queue is empty (puzzle has no solution)
      //synchronized (queue) {
        int qLen = _queue.length;
        if (qLen == 0) {
          bool allWaiting = true;
          for (SlaveThread s in _slaves) {
            if (!s._waiting) {
              allWaiting = false;
              break;
            }
          }
          if (allWaiting) {
            //no work, no solution ==> can't solve
            ret = null;
            done = true;
          }
        }
      //}
      if (done) {
        break;
      }
    }
    stopASAP = true;
    cachedResult = ret;
    solved = true;
    masterPaused = true;
    // Thread.currentThread().setPriority(oldPriority);
    // Thread.currentThread().setName(oldName);
    return ret;
  }

  /**
   * used by gui to fetch the current board status from all slaves (copy, or
   * null if concurrent access occurs). ignore.
   *
   * @return array of nCores int[rows][cols]. only 1 if puzzle is solved. some
   * may be null. null if puzzle has no solution.
   */
  List<List<List<int>>?>? __status() {
    if (solved) {
      if (cachedResult != null) {
        //int[][][] ret = new int[1][cachedResult.board.length][cachedResult.board[0].length];
        var ret = List<List<List<int>>>.generate(1, (y) =>
                        List<List<int>>.generate(cachedResult!._board.length, (i) =>
                              List<int>.generate(cachedResult!._board[0].length, (index) => cachedResult!._board[y][index], growable: false), growable: false));
        // for (int y = 0; y < cachedResult.board.length; y++) {
        //     System.arraycopy(cachedResult.board[y], 0, ret[0][y], 0, cachedResult.board[0].length);
        // }
        return ret;
      } else {
        return null;
      }
    } else {
      // List<List<List<int>>> ret = new int[slaves.length][][];
      var ret = List<List<List<int>>?>.generate(_slaves.length, (i) => [[]]);
      for (int i = 0; i < _slaves.length; i++) {
        try {
          var board = _slaves[i].__board;
          // int[][] bcopy = new int[board.length][board[0].length];
          var bcopy = List<List<int>>.generate(board.length, (i) => List<int>.generate(board[i].length, (index) => board[i][index], growable: false), growable: false);
          // for (int y = 0; y < board.length; y++) {
          //     System.arraycopy(board[y], 0, bcopy[y], 0, board[0].length);
          // }
          ret[i] = bcopy;
        } catch (e) {
          ret[i] = null;
        }
      }
      return ret;
    }
  }

  // /**
  //  *
  //  * @return number of processed work units
  //  */
  // int getIterations() {
  //   return iterations;
  // }

  /**
   * @return number of O blocks
   */
  int getOBlocks() {
    int ret = 0;
    for (String c in _blocks) {
      if (c == O) {
        ret++;
      }
    }
    return ret;
  }

  /**
   * @return number of T blocks
   */
  int getTBlocks() {
    int ret = 0;
    for (String c in _blocks) {
      if (c == T) {
        ret++;
      }
    }
    return ret;
  }

  /**
   * @return number of J blocks
   */
  int getJBlocks() {
    int ret = 0;
    for (String c in _blocks) {
      if (c == J) {
        ret++;
      }
    }
    return ret;
  }

  /**
   * @return number of L blocks
   */
  int getLBlocks() {
    int ret = 0;
    for (String c in _blocks) {
      if (c == L) {
        ret++;
      }
    }
    return ret;
  }

  /**
   * @return number of S blocks
   */
  int getSBlocks() {
    int ret = 0;
    for (String c in _blocks) {
      if (c == S) {
        ret++;
      }
    }
    return ret;
  }

  /**
   * @return number of Z blocks
   */
  int getZBlocks() {
    int ret = 0;
    for (String c in _blocks) {
      if (c == Z) {
        ret++;
      }
    }
    return ret;
  }
}

/**
 * this is a work unit.
 */
class BoardState {

  late List<List<int>> board; //board state

  int _p = 1; //pointer to next block to add (starts from 1, ends at blocks.length). this means that the higher p is, the closer we are to completing the puzzle
int threadIndex = -1; //ToDo wieder raus

  /**
   * creates a new work unit
   *
   * @param width columns
   * @param height rows
   */
  static BoardState _create(int width, int height) {
    if (width <= 0 || height <= 0) {
      //throw new IllegalArgumentException("Width and height must be >0");
    }
    var newBoardstate = BoardState();
    newBoardstate.board = List<List<int>>.generate(height, (i) => List<int>.generate(width, (index) => 0, growable: false), growable: false);
    return newBoardstate;
    // board = new int[height][width];
    // for (int y = 0; y < height; y++) {
    //     for (int x = 0; x < width; x++) {
    //         board[y][x] = 0;
    //     }
    // }
  }

  /**
   * clones a work unit. p is incremented because work units are cloned
   * only when the next block needs to be added
   *
   * @param s BoardState to clone
   */
  static BoardState _clone(BoardState s, int threadIndex) { //ToDo threadIndex wieder raus
    var newBoardstate = BoardState();
    newBoardstate.board =  List<List<int>>.generate(s.board.length, (i) => List<int>.generate(s.board[i].length, (index) => s.board[i][index], growable: false), growable: false);

      // board = new int[s.board.length][s.board[0].length];
      // for (int y = 0; y < board.length; y++) {
      //     System.arraycopy(s.board[y], 0, board[y], 0, board[0].length);
      // }
    newBoardstate._p = s._p + 1;
    newBoardstate.threadIndex = threadIndex;
    return newBoardstate;
  }

  //used by isStupid
  int _group(int y, int x) {
    if (y >= 0 && y < board.length && x >= 0 && x < board[0].length && board[y][x] == 0) {
      board[y][x] = -1;
      return 1 + _group(y, x + 1) + _group(y, x - 1) + _group(y + 1, x) + _group(y - 1, x);
    }
    return 0;
  }

  //used by isStupid
  void _clearGroups() {
    for (int y = 0; y < board.length; y++) {
      for (int x = 0; x < board[0].length; x++) {
        if (board[y][x] == -1) {
          board[y][x] = 0;
        }
      }
    }
  }

  /**
   * scans the board and creates groups of adjacent empty cells. if a
   * group's number of cells cannot be divided by 4, it cannot be filled
   * by tetraminos (as they take 4 cells each), and therefore the status
   * is considered stupid as it will never lead to a solution.
   *
   * @return false if no such groups are found, true otherwise
   */
  bool isStupid() {
    for (int y = 0; y < board.length; y++) {
      for (int x = 0; x < board[0].length; x++) {
        if (board[y][x] == 0) {
          if (_group(y, x) % 4 != 0) {
            _clearGroups();
            return true;
          }
        }
      }
    }
    _clearGroups();
    return false;
  }
}

/**
 * a board that solves the puzzle
 */
class _Solution {

  late List<List<int>> _board;

  /**
   * copies the solution from a BoardState
   *
   * @param s work unit
   */
  static _Solution copy(BoardState s) {
    var newSolution = _Solution();
    newSolution._board = List<List<int>>.generate(s.board.length, (i) => List<int>.generate(s.board[i].length, (index) => s.board[i][index], growable: false), growable: false);

    // board = new int[s.board.length][s.board[0].length];
    // for (int y = 0; y < board.length; y++) {
    //     System.arraycopy(s.board[y], 0, board[y], 0, board[0].length);
    // }
    return newSolution;
  }

  /**
   * creates a new instance using the given reference. used by save/load
   * methods to speed things up
   *
   * @param board reference
   */
  static _Solution clone(List<List<int>> board) {
    var newSolution = _Solution();
    newSolution._board = board;
    return newSolution;
  }

  /**
   *
   * @return number of rows
   */
  int getRows() {
    return _board.length;
  }

  /**
   *
   * @return number of columns
   */
  int getColumns() {
    return _board[0].length;
  }

  /**
   * get the content of a cell in the solution
   *
   * @param row row
   * @param col column
   * @return content
   */
  int get(int row, int col) {
    return _board[row][col];
  }

  /**
   * get a copy of the solution
   *
   * @return
   */
  List<List<int>> getCopy() { //ToDo get ???
    var copy = List<List<int>>.generate(_board.length, (i) => List<int>.generate(_board[i].length, (index) => _board[i][index], growable: false), growable: false);

    //     int[][] copy = new int[board.length][board[0].length];
    // for (int y = 0; y < board.length; y++) {
    // System.arraycopy(board[y], 0, copy[y], 0, board[0].length);
    // }
    return copy;
  }
}

class SlaveThread  { //extends Thread

  bool _waiting = false; //set to true when no work units are available. if all threads are waiting and the work queue is empty, the puzzle has no solution and the master thread will stop processing
  _Solution? solution; //set to an instance of Solution if this threads finds a solution
  late List<List<int>> __board; //board that it's currently working on. a reference is kept here so a copy can be passed to the gui to show the animation. ignore.
  bool _slavePaused = true; //set to true when it's paused in a safe state
  final List<String> _blocks;
  final List<BoardState> _queue;
  final int threadIndex; //ToDo wieder raus
  int loopCounter = 0; //ToDo wieder raus
  
  SlaveThread(this._blocks, this._queue, this.threadIndex);  //ToDo threadIndex wieder raus

  Future<_Solution?> run() async {
    _slavePaused = false;
    // setPriority(MAX_PRIORITY);
    // setName("TPS_SLAVE");
    BoardState? workunit;
    for (;;) {
      workunit = null;
      while (true) {
        //safe state for pausing
        // if (paused) {
        //   while (paused) {
        //     slavePaused = true;
        //     // try {
        //     //   sleep(100);
        //     // } catch (InterruptedException ex) {
        //     // }
        //   }
        //   slavePaused = false;
        // }
        // //safe state to interrupt processing
        // if (stopASAP) {
        //   slavePaused = true;
        //   return solution;
        // }
        // //get a work unit
        //synchronized (queue) {
          if (_queue.isNotEmpty) {
            //a work unit is available. fetch and remove from queue (actually a stack so work units with higher p (closer to solution) are processed first)
            _waiting = false;
            workunit = _queue.last;
            _queue.removeLast();
            //iterations++;
            // if (waiting) {
            //   setPriority(MAX_PRIORITY);
            // }
            break;
          } else {
            //a work unit is not available. check back later
            if (!_waiting) {
              // setPriority(MIN_PRIORITY);
              _waiting = true;
            }
            return null;
          }
        //}
      }


      loopCounter++;
      if (loopCounter % 1000 == 0) {
print(threadIndex.toString() + " " + _queue.length.toString() + " " + loopCounter.toString());
      }
      //at this point we surely have a work unit to process
      final List<List<int>> _board = workunit.board; //extract board
      __board = _board; //copy reference (for gui). ignore.
      final _p = workunit._p;
      final _block = _blocks[_p - 1]; //which block do we have to place? (p-1 because p starts from 1)
      var toAdd = <BoardState>[]; //this list will contain all the newly created work units
      //find ALL places where we can place this block. for each place, a new work unit is created with the block in that location
      if (_block == TetrisPuzzleSolverMT.I) {
        //I shaped block can have 2 rotations.
        /*
         #
         #
         #
         #
         */
        for (int y = 0; y <= _board.length - 4; y++) {
          for (int x = 0; x <= _board[0].length - 1; x++) {
            if (_board[y][x] == 0 && _board[y + 1][x] == 0 && _board[y + 2][x] == 0 && _board[y + 3][x] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y + 1][x] = _p;
              _board[y + 2][x] = _p;
              _board[y + 3][x] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y + 1][x] = 0;
              _board[y + 2][x] = 0;
              _board[y + 3][x] = 0;
            }
          }
        }
        // ####
        for (int y = 0; y <= _board.length - 1; y++) {
          for (int x = 0; x <= _board[0].length - 4; x++) {
            if (_board[y][x] == 0 && _board[y][x + 1] == 0 && _board[y][x + 2] == 0 && _board[y][x + 3] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y][x + 1] = _p;
              _board[y][x + 2] = _p;
              _board[y][x + 3] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y][x + 1] = 0;
              _board[y][x + 2] = 0;
              _board[y][x + 3] = 0;
            }
          }
        }
      }
      
      if (_block == TetrisPuzzleSolverMT.O) {
        //2x2 square block can have only 1 rotation
        for (int y = 0; y <= _board.length - 2; y++) {
          for (int x = 0; x <= _board[0].length - 2; x++) {
            if (_board[y][x] == 0 && _board[y + 1][x] == 0 && _board[y][x + 1] == 0 && _board[y + 1][x + 1] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y + 1][x] = _p;
              _board[y][x + 1] = _p;
              _board[y + 1][x + 1] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y + 1][x] = 0;
              _board[y][x + 1] = 0;
              _board[y + 1][x + 1] = 0;
            }
          }
        }
      }
  
      if (_block == TetrisPuzzleSolverMT.T) {
        //T shaped block can have 4 rotations
        /*
         ###
         _#
         */
        for (int y = 0; y <= _board.length - 2; y++) {
          for (int x = 0; x <= _board[0].length - 3; x++) {
            if (_board[y][x] == 0 && _board[y][x + 1] == 0 && _board[y + 1][x + 1] == 0 && _board[y][x + 2] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y][x + 1] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y][x + 2] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y][x + 1] = 0;
              _board[y + 1][x + 1] = 0;
              _board[y][x + 2] = 0;
            }
          }
        }
        /*
         #
         ##
         #
         */
        for (int y = 0; y <= _board.length - 3; y++) {
          for (int x = 0; x <= _board[0].length - 2; x++) {
            if (_board[y][x] == 0 && _board[y + 1][x] == 0 && _board[y + 1][x + 1] == 0 && _board[y + 2][x] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y + 1][x] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y + 2][x] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
              if (!workunit.isStupid()) {
                toAdd.add(BoardState._clone(workunit, threadIndex));
              }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y + 1][x] = 0;
              _board[y + 1][x + 1] = 0;
              _board[y + 2][x] = 0;
            }
          }
        }
        /*
         _#
         ##
         _#
         */
        for (int y = 0; y <= _board.length - 3; y++) {
          for (int x = 0; x <= _board[0].length - 2; x++) {
            if (_board[y][x + 1] == 0 && _board[y + 1][x] == 0 && _board[y + 1][x + 1] == 0 && _board[y + 2][x + 1] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x + 1] = _p;
              _board[y + 1][x] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y + 2][x + 1] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x + 1] = 0;
              _board[y + 1][x] = 0;
              _board[y + 1][x + 1] = 0;
              _board[y + 2][x + 1] = 0;
            }
          }
        }
        /*
         _#
         ###
         */
        for (int y = 0; y <= _board.length - 2; y++) {
          for (int x = 0; x <= _board[0].length - 3; x++) {
            if (_board[y + 1][x] == 0 && _board[y][x + 1] == 0 && _board[y + 1][x + 1] == 0 && _board[y + 1][x + 2] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y + 1][x] = _p;
              _board[y][x + 1] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y + 1][x + 2] = _p;
              if (_p == _blocks.length) { //solution found!
              solution = _Solution.copy(workunit);
              _slavePaused = true;
              return solution;
            } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
              if (!workunit.isStupid()) {
                toAdd.add(BoardState._clone(workunit, threadIndex));
              }
            }
            //remove changes, keep looking
            _board[y + 1][x] = 0;
            _board[y][x + 1] = 0;
            _board[y + 1][x + 1] = 0;
            _board[y + 1][x + 2] = 0;
            }
          }
        }
      }
  
      if (_block == TetrisPuzzleSolverMT.J) {
        //J shaped block can have 4 rotations
        /*
         ###
         __#
         */
        for (int y = 0; y <= _board.length - 2; y++) {
          for (int x = 0; x <= _board[0].length - 3; x++) {
            if (_board[y][x] == 0 && _board[y][x + 1] == 0 && _board[y + 1][x + 2] == 0 && _board[y][x + 2] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y][x + 1] = _p;
              _board[y + 1][x + 2] = _p;
              _board[y][x + 2] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y][x + 1] = 0;
              _board[y + 1][x + 2] = 0;
              _board[y][x + 2] = 0;
            }
          }
        }
        /*
         #
         ###
         */
        for (int y = 0; y <= _board.length - 2; y++) {
          for (int x = 0; x <= _board[0].length - 3; x++) {
            if (_board[y + 1][x] == 0 && _board[y][x] == 0 && _board[y + 1][x + 1] == 0 && _board[y + 1][x + 2] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y + 1][x] = _p;
              _board[y][x] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y + 1][x + 2] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y + 1][x] = 0;
              _board[y][x] = 0;
              _board[y + 1][x + 1] = 0;
              _board[y + 1][x + 2] = 0;
            }
          }
        }
        /*
         ##
         #
         #
         */
        for (int y = 0; y <= _board.length - 3; y++) {
          for (int x = 0; x <= _board[0].length - 2; x++) {
            if (_board[y][x] == 0 && _board[y + 1][x] == 0 && _board[y][x + 1] == 0 && _board[y + 2][x] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y + 1][x] = _p;
              _board[y][x + 1] = _p;
              _board[y + 2][x] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y + 1][x] = 0;
              _board[y][x + 1] = 0;
              _board[y + 2][x] = 0;
            }
          }
        }
        /*
         _#
         _#
         ##
         */
        for (int y = 0; y <= _board.length - 3; y++) {
          for (int x = 0; x <= _board[0].length - 2; x++) {
            if (_board[y][x + 1] == 0 && _board[y + 2][x] == 0 && _board[y + 1][x + 1] == 0 && _board[y + 2][x + 1] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x + 1] = _p;
              _board[y + 2][x] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y + 2][x + 1] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x + 1] = 0;
              _board[y + 2][x] = 0;
              _board[y + 1][x + 1] = 0;
              _board[y + 2][x + 1] = 0;
            }
          }
        }
      }
  
      if (_block == TetrisPuzzleSolverMT.L) {
        //L shaped block can have 4 rotations
        /*
         ###
         #
         */
        for (int y = 0; y <= _board.length - 2; y++) {
          for (int x = 0; x <= _board[0].length - 3; x++) {
            if (_board[y][x] == 0 && _board[y][x + 1] == 0 && _board[y + 1][x] == 0 && _board[y][x + 2] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y][x + 1] = _p;
              _board[y + 1][x] = _p;
              _board[y][x + 2] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y][x + 1] = 0;
              _board[y + 1][x] = 0;
              _board[y][x + 2] = 0;
            }
          }
        }
        /*
         #
         #
         ##
         */
        for (int y = 0; y <= _board.length - 3; y++) {
          for (int x = 0; x <= _board[0].length - 2; x++) {
            if (_board[y][x] == 0 && _board[y + 1][x] == 0 && _board[y + 2][x + 1] == 0 && _board[y + 2][x] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y + 1][x] = _p;
              _board[y + 2][x + 1] = _p;
              _board[y + 2][x] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y + 1][x] = 0;
              _board[y + 2][x + 1] = 0;
              _board[y + 2][x] = 0;
            }
          }
        }
        /*
         ##
         _#
         _#
         */
        for (int y = 0; y <= _board.length - 3; y++) {
          for (int x = 0; x <= _board[0].length - 2; x++) {
            if (_board[y][x + 1] == 0 && _board[y][x] == 0 && _board[y + 1][x + 1] == 0 && _board[y + 2][x + 1] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x + 1] = _p;
              _board[y][x] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y + 2][x + 1] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
              if (!workunit.isStupid()) {
                toAdd.add(BoardState._clone(workunit, threadIndex));
              }
              }
              //remove changes, keep looking
              _board[y][x + 1] = 0;
              _board[y][x] = 0;
              _board[y + 1][x + 1] = 0;
              _board[y + 2][x + 1] = 0;
            }
          }
        }
        /*
         __#
         ###
         */
        for (int y = 0; y <= _board.length - 2; y++) {
          for (int x = 0; x <= _board[0].length - 3; x++) {
            if (_board[y + 1][x] == 0 && _board[y][x + 2] == 0 && _board[y + 1][x + 1] == 0 && _board[y + 1][x + 2] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y + 1][x] = _p;
              _board[y][x + 2] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y + 1][x + 2] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y + 1][x] = 0;
              _board[y][x + 2] = 0;
              _board[y + 1][x + 1] = 0;
              _board[y + 1][x + 2] = 0;
            }
          }
        }
      }
  
      if (_block == TetrisPuzzleSolverMT.S) {
        //S shaped block can have 2 rotations
        /*
         #
         ##
         _#
         */
        for (int y = 0; y <= _board.length - 3; y++) {
          for (int x = 0; x <= _board[0].length - 2; x++) {
            if (_board[y][x] == 0 && _board[y + 1][x] == 0 && _board[y + 1][x + 1] == 0 && _board[y + 2][x + 1] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y + 1][x] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y + 2][x + 1] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y + 1][x] = 0;
              _board[y + 1][x + 1] = 0;
              _board[y + 2][x + 1] = 0;
            }
          }
        }
        /*
         _##
         ##
         */
        for (int y = 0; y <= _board.length - 2; y++) {
          for (int x = 0; x <= _board[0].length - 3; x++) {
            if (_board[y][x + 1] == 0 && _board[y][x + 2] == 0 && _board[y + 1][x] == 0 && _board[y + 1][x + 1] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x + 1] = _p;
              _board[y][x + 2] = _p;
              _board[y + 1][x] = _p;
              _board[y + 1][x + 1] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x + 1] = 0;
              _board[y][x + 2] = 0;
              _board[y + 1][x] = 0;
              _board[y + 1][x + 1] = 0;
            }
          }
        }
      }

      if (_block == TetrisPuzzleSolverMT.Z) {
        //Z shaped block can have 2 rotations
        /*
         **
         _**
         */
        for (int y = 0; y <= _board.length - 2; y++) {
          for (int x = 0; x <= _board[0].length - 3; x++) {
            if (_board[y][x] == 0 && _board[y][x + 1] == 0 && _board[y + 1][x + 1] == 0 && _board[y + 1][x + 2] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x] = _p;
              _board[y][x + 1] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y + 1][x + 2] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x] = 0;
              _board[y][x + 1] = 0;
              _board[y + 1][x + 1] = 0;
              _board[y + 1][x + 2] = 0;
            }
          }
        }
        /*
         _#
         ##
         #
         */
        for (int y = 0; y <= _board.length - 3; y++) {
          for (int x = 0; x <= _board[0].length - 2; x++) {
            if (_board[y][x + 1] == 0 && _board[y + 1][x] == 0 && _board[y + 1][x + 1] == 0 && _board[y + 2][x] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              _board[y][x + 1] = _p;
              _board[y + 1][x] = _p;
              _board[y + 1][x + 1] = _p;
              _board[y + 2][x] = _p;
              if (_p == _blocks.length) { //solution found!
                solution = _Solution.copy(workunit);
                _slavePaused = true;
                return solution;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState._clone(workunit, threadIndex));
                }
              }
              //remove changes, keep looking
              _board[y][x + 1] = 0;
              _board[y + 1][x] = 0;
              _board[y + 1][x + 1] = 0;
              _board[y + 2][x] = 0;
            }
          }
        }
      }

      if (toAdd.isNotEmpty) { //we got work to add to the main queue
        //synchronized (queue) {
          _queue.addAll(toAdd);
        //}
      }
    }

  }
}
