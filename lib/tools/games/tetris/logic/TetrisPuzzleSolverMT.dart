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

import 'dart:core';
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

  late final List<String> blocks; //blocks to add

  var queue = <BoardState>[]; //this contains all the work units. work units are added and removed by SlaveThreads
  int iterations = 0; //number of processed work units

  bool stopASAP = false; //set to true to cancel computation
  bool paused = false, masterPaused = true; //used by save/load methods. setting paused to true causes all threads to stop as soon as possible in a safe state. masterPaused is set to true by the master thread when it's paused in a safe state

  late List<SlaveThread> slaves; //[Runtime.getRuntime().availableProcessors()]; //1 slave thread per core (+1 master thread)

  //initialize slaves (without actually starting them)
  // {
  //     for (int i = 0; i < slaves.length; i++) {
  //         slaves[i] = new SlaveThread();
  //     }
  // }

  late int w, h; //cols and rows of the board

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
    w = width;
    h = height;
    int nBlocks = iBlocks + oBlocks + tBlocks + jBlocks + lBlocks + sBlocks + zBlocks;
    blocks = List<String>.filled(nBlocks, '');
    slaves = List<SlaveThread>.filled(4, SlaveThread(blocks, queue));

    int p = 0;
    for (int i = 0; i < iBlocks; i++) {
      blocks[p++] = I;
    }
    for (int i = 0; i < oBlocks; i++) {
      blocks[p++] = O;
    }
    for (int i = 0; i < tBlocks; i++) {
      blocks[p++] = T;
    }
    for (int i = 0; i < jBlocks; i++) {
      blocks[p++] = J;
    }
    for (int i = 0; i < lBlocks; i++) {
      blocks[p++] = L;
    }
    for (int i = 0; i < sBlocks; i++) {
      blocks[p++] = S;
    }
    for (int i = 0; i < zBlocks; i++) {
      blocks[p++] = Z;
    }
    //scramble blocks. seems to lead to a solution faster
    for(int i = 0; i < nBlocks; i++){
      int r=(Random().nextDouble()*nBlocks).toInt();
      int r2=(Random().nextDouble()*nBlocks).toInt();
      var temp=blocks[r];
      blocks[r]=blocks[r2];
      blocks[r2]=temp;
    }
    if (nBlocks * 4 != width * height) {
      solved = true;
      cachedResult = null;
      return;
    }
    //create and add the first work unit, initially empty.
    BoardState s = BoardState.create(width, height);
    queue.add(s);
  }

  /**
   *
   * @return columns
   */
  int getWidth() {
    return w;
  }

  /**
   *
   * @return rows
   */
  int getHeight() {
    return h;
  }

  /**
   *
   * @return number of pieces
   */
  int getNumberOfPieces() {
    return blocks.length;
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

  /**
   *
   * @return number of slave threads
   */
  int getNCores() {
    return slaves.length;
  }

  bool solved = false; //set to indicate that the solve() method has been called and has finished processing (or was canceled)
  Solution? cachedResult; //the result of the solve() method so it doesn't need to be calculated again. null if no solution was found (or solve() was canceled)

  /**
   * solve the puzzle. blocking. use cancel() to stop solving
   *
   * @return an instance of Solution if the puzzle has a solution, null if it
   * doesn't (or if cancel() was called)
   */
  Solution? solve() {
    if (solved) { //already solved
      return cachedResult!;
    }
    masterPaused = false;
    //set current thread as master
    // int oldPriority = Thread.currentThread().getPriority();
    // Thread.currentThread().setPriority(Thread.NORM_PRIORITY);
    // String oldName = Thread.currentThread().getName();
    // Thread.currentThread().setName("TPS_MASTER");
    Solution? ret; //this will contain the return value (Solution or null)
    //start slaves
    for (SlaveThread s in slaves) {
      s.run();
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
      for (SlaveThread s in slaves) {
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
        int qLen = queue.length;
        if (qLen == 0) {
          bool allWaiting = true;
          for (SlaveThread s in slaves) {
            if (!s.waiting) {
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
                        List<List<int>>.generate(cachedResult!.board.length, (i) =>
                              List<int>.generate(cachedResult!.board[0].length, (index) => cachedResult!.board[y][index], growable: false), growable: false));
        // for (int y = 0; y < cachedResult.board.length; y++) {
        //     System.arraycopy(cachedResult.board[y], 0, ret[0][y], 0, cachedResult.board[0].length);
        // }
        return ret;
      } else {
        return null;
      }
    } else {
      // List<List<List<int>>> ret = new int[slaves.length][][];
      var ret = List<List<List<int>>?>.generate(slaves.length, (i) => [[]]);
      for (int i = 0; i < slaves.length; i++) {
        try {
          var board = slaves[i].__board;
          // int[][] bcopy = new int[board.length][board[0].length];
          var bcopy = List<List<int>>.generate(board.length, (i) => List<int>.generate(board[i].length, (index) => board[i][index], growable: false), growable: false);
          // for (int y = 0; y < board.length; y++) {
          //     System.arraycopy(board[y], 0, bcopy[y], 0, board[0].length);
          // }
          ret[i] = bcopy;
        } catch (Throwable t) {
          ret[i] = null;
        }
      }
      return ret;
    }
  }

  /**
   *
   * @return number of processed work units
   */
  int getIterations() {
    return iterations;
  }

  /**
   * cancels processing. use to stop solve() method while processing. waits
   * for threads to actually stop.
   */
  void cancel() {
    stopASAP = true;
    while (!masterPaused) {
      // try {
      //   Thread.sleep(1);
      // } catch (InterruptedException ex) {
      // }
    }
    // for (SlaveThread s in slaves) {
    //   while (s.isAlive()) {
    //     // try {
    //     //   Thread.sleep(1);
    //     // } catch (InterruptedException ex) {
    //     // }
    //   }
    // }
  }

  // /**
  //  * the following methods contain code for saving and loading the state.
  //  *
  //  * java serialization is not used because it produced heeeeeug files, so
  //  * here's the file format instead:
  //  *
  //  * 4 bytes: magic number, which spells >muh in ascii<br>
  //  * 4 bytes: rows (as int)<br>
  //  * 4 bytes: cols (as int)<br>
  //  * 4 bytes: length of blocks array (number of pieces)<br>
  //  * 2*blocks.length bytes: contents of blocks array (as chars, so it's
  //  * unicode)<br>
  //  * 1 byte: solved status: 2=solved, has no solution, 1=solved, solution
  //  * follows, 0=not solved yet, saved state follows<br>
  //  * *** if 1: 4*rows*cols bytes contain the solution board as a sequence of
  //  * ints, serialized "c style". see serializeBoard and deserializeBoard for
  //  * details<br>
  //  * *** if 0: 4 bytes contain the number of work units that follow (as int).
  //  * for each unit: 4*rows*cols bytes for the board (see row above) + 4 bytes
  //  * for the value of p for that unit (as int)<br>
  //  * 4 bytes: magic number again, indicating proper end of file
  //  */
  // static final MAGIC = {0x3e, 0x6d, 0x75, 0x68};
  //
  // /**
  //  * write board to specified DataOutputStream. it dumps the contents "c
  //  * style" (row per row, element by element for each row). size is not
  //  * written!
  //  *
  //  * @param board board to serialize
  //  * @param dos stream
  //  * @throws IOException if writing fails
  //  */
  // void serializeBoard(List<List<int>> board, Int8List dos) { //throws IOException
  //     for (int y = 0; y < board.length; y++) {
  //         for (int x = 0; x < board[0].length; x++) {
  //             dos.writeInt(board[y][x]);
  //         }
  //     }
  // }

  // /**
  //  * deserialize a bunch of ints from the given DataInputStream into a board,
  //  * and stores it into the given board. rows and cols are taken from board
  //  * size.
  //  *
  //  * @param board target
  //  * @param is stream
  //  * @throws IOException if read fails
  //  */
  // static void deserializeBoard(List<List<int>> board, Int8List data) { //throws IOException
  //     for (int y = 0; y < board.length; y++) {
  //         for (int x = 0; x < board[0].length; x++) {
  //             board[y][x] = data.readInt();
  //         }
  //     }
  // }
  //
  // var saveLock = Object(); //used to prevent concurrent calls of saveState method
  //
  // /**
  //  * save current state to specified OutputStream
  //  *
  //  * @param os target stream
  //  * @throws IOException if write fails
  //  */
  // void saveState(Int8List os) { //throws IOException
  //     synchronized (saveLock) {
  //         try {
  //             //DataOutputStream dos = new DataOutputStream(os);
  //             //write magic number
  //             dos.write(MAGIC);
  //             //write config (rows,cols,blocks)
  //             dos.writeInt(h);
  //             dos.writeInt(w);
  //             dos.writeInt(blocks.length);
  //             for (String c in blocks) {
  //                 dos.writeChar(c);
  //             }
  //             //pause all computation
  //             paused = true;
  //             //wait for threads to actually pause
  //             while (!masterPaused) {
  //                 try {
  //                     Thread.sleep(1);
  //                 } catch (InterruptedException ex) {
  //                 }
  //             }
  //             for (SlaveThread s : slaves) {
  //                 while (!s.slavePaused) {
  //                     try {
  //                         Thread.sleep(1);
  //                     } catch (InterruptedException ex) {
  //                     }
  //                 }
  //             }
  //             //we're now in a safe state
  //             if (solved) { //already solved
  //                 if (cachedResult == null) {
  //                     //puzzle is impossible
  //                     dos.writeByte(2);
  //                 } else {
  //                     //solution found
  //                     dos.writeByte(1);
  //                     serializeBoard(cachedResult.board, dos);
  //                 }
  //             } else {
  //                 //not solved yet
  //                 //check to see if the puzzle is actually solved but the master hasn't noticed yet
  //                 if (queue.isEmpty()) {
  //                     //puzzle is impossible
  //                     dos.writeByte(2);
  //                 } else {
  //                     Solution sol = null;
  //                     for (SlaveThread s : slaves) {
  //                         if (s.solution != null) {
  //                             sol = s.solution;
  //                             break;
  //                         }
  //                     }
  //                     if (sol != null) {
  //                         //a thread found the solution
  //                         dos.writeByte(1);
  //                         serializeBoard(sol.board, dos);
  //                     } else {
  //                         //actually solving: save state
  //                         dos.writeByte(0);
  //                         dos.writeInt(queue.size());
  //                         for (BoardState s : queue) {
  //                             serializeBoard(s.board, dos);
  //                             dos.writeInt(s.p);
  //                         }
  //                     }
  //                 }
  //
  //             }
  //             //write magic number again to indicate end of saved state
  //             dos.write(MAGIC);
  //             dos.flush();
  //             paused = false;
  //         } catch (Throwable t) {
  //             //System.out.println(t);
  //             paused = false;
  //             if (t instanceof IOException) {
  //                 //throw (IOException) t;
  //             } else {
  //                 //throw new IOException(t);
  //             }
  //         }
  //     }
  // }

  // /**
  //  * load state from specified InputStream. solve() needs to be called to
  //  * resume computation
  //  *
  //  * @param is stream
  //  * @return instance of solver. call solve() on it.
  //  * @throws IOException if read error occurs
  //  */
  // static TetrisPuzzleSolverMT loadState(Int8List data)  { //throws IOException
  //     //DataInputStream dis = new DataInputStream(is);
  //     var ret = TetrisPuzzleSolverMT(1, 1, 1, 1, 1, 1, 1, 1, 1); //initial dummy state
  //     //check magic bytes at beginning
  //     var magic = List<int>.filled(MAGIC.length, 0, growable: false);
  // MAGIC.ListEquality(data.sublist(0, MAGIC.length));
  //     dis.read(magic);
  //     for (int i = 0; i < MAGIC.length; i++) {
  //         if (magic[i] != MAGIC[i]) {
  //             //throw new IOException("Not a valid saved state");
  //         }
  //     }
  //     //read rows and cols
  //     int rows = dis.readInt(), cols = dis.readInt();
  //     if (rows < 1 || cols < 1) {
  //         //throw new IOException("Not a valid saved state");
  //     }
  //     //read blocks array
  //     int nBlocks = dis.readInt();
  //     if (nBlocks < 1) {
  //         //throw new IOException("Not a valid saved state");
  //     }
  //     var blocks = <String>[nBlocks];
  //     for (int i = 0; i < nBlocks; i++) {
  //         blocks[i] = dis.readChar();
  //         if (blocks[i] != I && blocks[i] != O && blocks[i] != T && blocks[i] != J && blocks[i] != L && blocks[i] != S && blocks[i] != Z) {
  //             //throw new IOException("Not a valid saved state");
  //         }
  //     }
  //     //setup solver instance
  //     ret.h = rows;
  //     ret.w = cols;
  //     ret.blocks = blocks;
  //     //read solved status
  //     int status = dis.readByte();
  //     if (status == 2) {
  //         //solved, impossible
  //         ret.queue.clear();
  //         ret.solved = true;
  //         ret.cachedResult = null;
  //     } else if (status == 1) {
  //         //solved, solution found
  //         var board = List<List<int>>.generate(rows, (i) => List<int>.generate(cols, (index) => 0, growable: false), growable: false);
  //         //int[][] board = new int[rows][cols];
  //         deserializeBoard(board, dis);
  //         var s = Solution(board);
  //         ret.queue.clear();
  //         ret.solved = true;
  //         ret.cachedResult = s;
  //     } else if (status == 0) {
  //         //not solved yet, load state
  //         ret.queue.clear();
  //         ret.solved = false;
  //         int nStates = dis.readInt();
  //         for (int i = 0; i < nStates; i++) {
  //             BoardState s = BoardState(cols, rows);
  //             deserializeBoard(s.board, dis);
  //             s.p = dis.readInt();
  //             ret.queue.add(s);
  //         }
  //     } else {
  //         //throw new IOException("Not a valid saved state");
  //     }
  //     //check magic bytes at end of file
  //     // magic = new byte[MAGIC.length]; ToDO
  //     // dis.read(magic);
  //     for (int i = 0; i < MAGIC.length; i++) {
  //         if (magic[i] != MAGIC[i]) {
  //             //throw new IOException("Not a valid saved state");
  //         }
  //     }
  //     //done, return solver instance
  //     return ret;
  // }
  //
  // /**
  //  *
  //  * @return number of I blocks
  //  */
  // int getIBlocks() {
  //     int ret = 0;
  //     for (String c in blocks) {
  //         if (c == I) {
  //             ret++;
  //         }
  //     }
  //     return ret;
  // }

  /**
   * @return number of O blocks
   */
  int getOBlocks() {
    int ret = 0;
    for (String c in blocks) {
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
    for (String c in blocks) {
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
    for (String c in blocks) {
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
    for (String c in blocks) {
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
    for (String c in blocks) {
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
    for (String c in blocks) {
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

  int p = 1; //pointer to next block to add (starts from 1, ends at blocks.length). this means that the higher p is, the closer we are to completing the puzzle

  BoardState();
  
  /**
   * creates a new work unit
   *
   * @param width columns
   * @param height rows
   */
  static BoardState create(int width, int height) {
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
  static BoardState clone(BoardState s) {
    var newBoardstate = BoardState();
    newBoardstate.board =  List<List<int>>.generate(s.board.length, (i) => List<int>.generate(s.board[i].length, (index) => s.board[i][index], growable: false), growable: false);

      // board = new int[s.board.length][s.board[0].length];
      // for (int y = 0; y < board.length; y++) {
      //     System.arraycopy(s.board[y], 0, board[y], 0, board[0].length);
      // }
    newBoardstate.p = s.p + 1;
    return newBoardstate;
  }

  //used by isStupid
  int group(int y, int x) {
    if (y >= 0 && y < board.length && x >= 0 && x < board[0].length && board[y][x] == 0) {
      board[y][x] = -1;
      return 1 + group(y, x + 1) + group(y, x - 1) + group(y + 1, x) + group(y - 1, x);
    }
    return 0;
  }

  //used by isStupid
  void clearGroups() {
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
          if (group(y, x) % 4 != 0) {
            clearGroups();
            return true;
          }
        }
      }
    }
    clearGroups();
    return false;
  }
}

/**
 * a board that solves the puzzle
 */
class Solution {

  late List<List<int>> board;

  Solution();
  
  /**
   * copies the solution from a BoardState
   *
   * @param s work unit
   */
  static Solution copy(BoardState s) {
    var newSolution = Solution();
    newSolution.board = List<List<int>>.generate(s.board.length, (i) => List<int>.generate(s.board[i].length, (index) => s.board[i][index], growable: false), growable: false);

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
  static Solution clone(List<List<int>> board) {
    var newSolution = Solution();
    newSolution.board = board;
    return newSolution;
  }

  /**
   *
   * @return number of rows
   */
  int getRows() {
    return board.length;
  }

  /**
   *
   * @return number of columns
   */
  int getColumns() {
    return board[0].length;
  }

  /**
   * get the content of a cell in the solution
   *
   * @param row row
   * @param col column
   * @return content
   */
  int get(int row, int col) {
    return board[row][col];
  }

  /**
   * get a copy of the solution
   *
   * @return
   */
  List<List<int>> getCopy() {
    var copy = List<List<int>>.generate(board.length, (i) => List<int>.generate(board[i].length, (index) => board[i][index], growable: false), growable: false);

    //     int[][] copy = new int[board.length][board[0].length];
    // for (int y = 0; y < board.length; y++) {
    // System.arraycopy(board[y], 0, copy[y], 0, board[0].length);
    // }
    return copy;
  }
}

class SlaveThread  { //extends Thread

  bool waiting = false; //set to true when no work units are available. if all threads are waiting and the work queue is empty, the puzzle has no solution and the master thread will stop processing
  late Solution? solution; //set to an instance of Solution if this threads finds a solution
  late List<List<int>> __board; //board that it's currently working on. a reference is kept here so a copy can be passed to the gui to show the animation. ignore.
  bool slavePaused = true; //set to true when it's paused in a safe state
  List<String> blocks;
  List<BoardState> queue;
  
  SlaveThread(this.blocks, this.queue);

  void run() {
    slavePaused = false;
    // setPriority(MAX_PRIORITY);
    // setName("TPS_SLAVE");
    BoardState? workunit;// = null;
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
        //   return;
        // }
        // //get a work unit
        //synchronized (queue) {
          if (queue.isNotEmpty) {
            //a work unit is available. fetch and remove from queue (actually a stack so work units with higher p (closer to solution) are processed first)
            waiting = false;
            workunit = queue.last;
            queue.removeLast();
            iterations++;
            // if (waiting) {
            //   setPriority(MAX_PRIORITY);
            // }
            break;
          } else {
            //a work unit is not available. check back later
            if (!waiting) {
              // setPriority(MIN_PRIORITY);
              waiting = true;
            }
          }
        //}
      }
      //at this point we surely have a work unit to process
      final List<List<int>> board = workunit.board; //extract board
      __board = board; //copy reference (for gui). ignore.
      final p = workunit.p;
      final block = blocks[p - 1]; //which block do we have to place? (p-1 because p starts from 1)
      var toAdd = <BoardState>[]; //this list will contain all the newly created work units
      //find ALL places where we can place this block. for each place, a new work unit is created with the block in that location
      if (block == TetrisPuzzleSolverMT.I) {
        //I shaped block can have 2 rotations.
        /*
         #
         #
         #
         #
         */
        for (int y = 0; y <= board.length - 4; y++) {
          for (int x = 0; x <= board[0].length - 1; x++) {
            if (board[y][x] == 0 && board[y + 1][x] == 0 && board[y + 2][x] == 0 && board[y + 3][x] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              board[y][x] = p;
              board[y + 1][x] = p;
              board[y + 2][x] = p;
              board[y + 3][x] = p;
              if (p == blocks.length) { //solution found!
                solution = Solution.copy(workunit);
                slavePaused = true;
                return;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState.clone(workunit));
                }
              }
              //remove changes, keep looking
              board[y][x] = 0;
              board[y + 1][x] = 0;
              board[y + 2][x] = 0;
              board[y + 3][x] = 0;
            }
          }
        }
        // ####
        for (int y = 0; y <= board.length - 1; y++) {
          for (int x = 0; x <= board[0].length - 4; x++) {
            if (board[y][x] == 0 && board[y][x + 1] == 0 && board[y][x + 2] == 0 && board[y][x + 3] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              board[y][x] = p;
              board[y][x + 1] = p;
              board[y][x + 2] = p;
              board[y][x + 3] = p;
              if (p == blocks.length) { //solution found!
                solution = Solution.copy(workunit);
                slavePaused = true;
                return;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState.clone(workunit));
                }
              }
              //remove changes, keep looking
              board[y][x] = 0;
              board[y][x + 1] = 0;
              board[y][x + 2] = 0;
              board[y][x + 3] = 0;
            }
          }
        }
      }
      
      if (block == TetrisPuzzleSolverMT.O) {
        //2x2 square block can have only 1 rotation
        for (int y = 0; y <= board.length - 2; y++) {
          for (int x = 0; x <= board[0].length - 2; x++) {
            if (board[y][x] == 0 && board[y + 1][x] == 0 && board[y][x + 1] == 0 && board[y + 1][x + 1] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              board[y][x] = p;
              board[y + 1][x] = p;
              board[y][x + 1] = p;
              board[y + 1][x + 1] = p;
              if (p == blocks.length) { //solution found!
                solution = Solution.copy(workunit);
                slavePaused = true;
                return;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState.clone(workunit));
                }
              }
              //remove changes, keep looking
              board[y][x] = 0;
              board[y + 1][x] = 0;
              board[y][x + 1] = 0;
              board[y + 1][x + 1] = 0;
            }
          }
        }
      }
  
      if (block == TetrisPuzzleSolverMT.T) {
      //T shaped block can have 4 rotations
      /*
       ###
       _#
       */
      for (int y = 0; y <= board.length - 2; y++) {
        for (int x = 0; x <= board[0].length - 3; x++) {
          if (board[y][x] == 0 && board[y][x + 1] == 0 && board[y + 1][x + 1] == 0 && board[y][x + 2] == 0) {
            //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
            board[y][x] = p;
            board[y][x + 1] = p;
            board[y + 1][x + 1] = p;
            board[y][x + 2] = p;
            if (p == blocks.length) { //solution found!
              solution = Solution.copy(workunit);
              slavePaused = true;
              return;
            } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
              if (!workunit.isStupid()) {
                toAdd.add(BoardState.clone(workunit));
              }
            }
            //remove changes, keep looking
            board[y][x] = 0;
            board[y][x + 1] = 0;
            board[y + 1][x + 1] = 0;
            board[y][x + 2] = 0;
          }
        }
      }
      /*
       #
       ##
       #
       */
      for (int y = 0; y <= board.length - 3; y++) {
        for (int x = 0; x <= board[0].length - 2; x++) {
          if (board[y][x] == 0 && board[y + 1][x] == 0 && board[y + 1][x + 1] == 0 && board[y + 2][x] == 0) {
            //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
            board[y][x] = p;
            board[y + 1][x] = p;
            board[y + 1][x + 1] = p;
            board[y + 2][x] = p;
            if (p == blocks.length) { //solution found!
              solution = Solution.copy(workunit);
              slavePaused = true;
              return;
            } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
            if (!workunit.isStupid()) {
              toAdd.add(BoardState.clone(workunit));
            }
            }
            //remove changes, keep looking
            board[y][x] = 0;
            board[y + 1][x] = 0;
            board[y + 1][x + 1] = 0;
            board[y + 2][x] = 0;
          }
        }
      }
      /*
       _#
       ##
       _#
       */
      for (int y = 0; y <= board.length - 3; y++) {
        for (int x = 0; x <= board[0].length - 2; x++) {
          if (board[y][x + 1] == 0 && board[y + 1][x] == 0 && board[y + 1][x + 1] == 0 && board[y + 2][x + 1] == 0) {
            //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
            board[y][x + 1] = p;
            board[y + 1][x] = p;
            board[y + 1][x + 1] = p;
            board[y + 2][x + 1] = p;
            if (p == blocks.length) { //solution found!
              solution = Solution.copy(workunit);
              slavePaused = true;
              return;
            } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
              if (!workunit.isStupid()) {
                toAdd.add(BoardState.clone(workunit));
              }
            }
            //remove changes, keep looking
            board[y][x + 1] = 0;
            board[y + 1][x] = 0;
            board[y + 1][x + 1] = 0;
            board[y + 2][x + 1] = 0;
          }
        }
      }
      /*
       _#
       ###
       */
      for (int y = 0; y <= board.length - 2; y++) {
        for (int x = 0; x <= board[0].length - 3; x++) {
          if (board[y + 1][x] == 0 && board[y][x + 1] == 0 && board[y + 1][x + 1] == 0 && board[y + 1][x + 2] == 0) {
            //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
            board[y + 1][x] = p;
            board[y][x + 1] = p;
            board[y + 1][x + 1] = p;
            board[y + 1][x + 2] = p;
            if (p == blocks.length) { //solution found!
            solution = Solution.copy(workunit);
            slavePaused = true;
            return;
          } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
            if (!workunit.isStupid()) {
              toAdd.add(BoardState.clone(workunit));
            }
          }
          //remove changes, keep looking
          board[y + 1][x] = 0;
          board[y][x + 1] = 0;
          board[y + 1][x + 1] = 0;
          board[y + 1][x + 2] = 0;
          }
        }
      }
      }
  
      if (block == TetrisPuzzleSolverMT.J) {
        //J shaped block can have 4 rotations
        /*
         ###
         __#
         */
        for (int y = 0; y <= board.length - 2; y++) {
          for (int x = 0; x <= board[0].length - 3; x++) {
            if (board[y][x] == 0 && board[y][x + 1] == 0 && board[y + 1][x + 2] == 0 && board[y][x + 2] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              board[y][x] = p;
              board[y][x + 1] = p;
              board[y + 1][x + 2] = p;
              board[y][x + 2] = p;
              if (p == blocks.length) { //solution found!
                solution = Solution.copy(workunit);
                slavePaused = true;
                return;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState.clone(workunit));
                }
              }
              //remove changes, keep looking
              board[y][x] = 0;
              board[y][x + 1] = 0;
              board[y + 1][x + 2] = 0;
              board[y][x + 2] = 0;
            }
          }
        }
        /*
         #
         ###
         */
        for (int y = 0; y <= board.length - 2; y++) {
          for (int x = 0; x <= board[0].length - 3; x++) {
            if (board[y + 1][x] == 0 && board[y][x] == 0 && board[y + 1][x + 1] == 0 && board[y + 1][x + 2] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              board[y + 1][x] = p;
              board[y][x] = p;
              board[y + 1][x + 1] = p;
              board[y + 1][x + 2] = p;
              if (p == blocks.length) { //solution found!
                solution = Solution.copy(workunit);
                slavePaused = true;
                return;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState.clone(workunit));
                }
              }
              //remove changes, keep looking
              board[y + 1][x] = 0;
              board[y][x] = 0;
              board[y + 1][x + 1] = 0;
              board[y + 1][x + 2] = 0;
            }
          }
        }
        /*
         ##
         #
         #
         */
        for (int y = 0; y <= board.length - 3; y++) {
          for (int x = 0; x <= board[0].length - 2; x++) {
            if (board[y][x] == 0 && board[y + 1][x] == 0 && board[y][x + 1] == 0 && board[y + 2][x] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              board[y][x] = p;
              board[y + 1][x] = p;
              board[y][x + 1] = p;
              board[y + 2][x] = p;
              if (p == blocks.length) { //solution found!
                solution = Solution.copy(workunit);
                slavePaused = true;
                return;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState.clone(workunit));
                }
              }
              //remove changes, keep looking
              board[y][x] = 0;
              board[y + 1][x] = 0;
              board[y][x + 1] = 0;
              board[y + 2][x] = 0;
            }
          }
        }
        /*
         _#
         _#
         ##
         */
        for (int y = 0; y <= board.length - 3; y++) {
          for (int x = 0; x <= board[0].length - 2; x++) {
            if (board[y][x + 1] == 0 && board[y + 2][x] == 0 && board[y + 1][x + 1] == 0 && board[y + 2][x + 1] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              board[y][x + 1] = p;
              board[y + 2][x] = p;
              board[y + 1][x + 1] = p;
              board[y + 2][x + 1] = p;
              if (p == blocks.length) { //solution found!
              solution = Solution.copy(workunit);
              slavePaused = true;
              return;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState.clone(workunit));
                }
              }
              //remove changes, keep looking
              board[y][x + 1] = 0;
              board[y + 2][x] = 0;
              board[y + 1][x + 1] = 0;
              board[y + 2][x + 1] = 0;
            }
          }
        }
      }
  
      if (block == TetrisPuzzleSolverMT.L) {
      //L shaped block can have 4 rotations
      /*
       ###
       #
       */
      for (int y = 0; y <= board.length - 2; y++) {
        for (int x = 0; x <= board[0].length - 3; x++) {
          if (board[y][x] == 0 && board[y][x + 1] == 0 && board[y + 1][x] == 0 && board[y][x + 2] == 0) {
            //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
            board[y][x] = p;
            board[y][x + 1] = p;
            board[y + 1][x] = p;
            board[y][x + 2] = p;
            if (p == blocks.length) { //solution found!
              solution = Solution.copy(workunit);
              slavePaused = true;
              return;
            } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
              if (!workunit.isStupid()) {
                toAdd.add(BoardState.clone(workunit));
              }
            }
            //remove changes, keep looking
            board[y][x] = 0;
            board[y][x + 1] = 0;
            board[y + 1][x] = 0;
            board[y][x + 2] = 0;
          }
        }
      }
      /*
       #
       #
       ##
       */
      for (int y = 0; y <= board.length - 3; y++) {
        for (int x = 0; x <= board[0].length - 2; x++) {
          if (board[y][x] == 0 && board[y + 1][x] == 0 && board[y + 2][x + 1] == 0 && board[y + 2][x] == 0) {
            //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
            board[y][x] = p;
            board[y + 1][x] = p;
            board[y + 2][x + 1] = p;
            board[y + 2][x] = p;
            if (p == blocks.length) { //solution found!
              solution = Solution.copy(workunit);
              slavePaused = true;
              return;
            } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
              if (!workunit.isStupid()) {
                toAdd.add(BoardState.clone(workunit));
              }
            }
            //remove changes, keep looking
            board[y][x] = 0;
            board[y + 1][x] = 0;
            board[y + 2][x + 1] = 0;
            board[y + 2][x] = 0;
          }
        }
      }
      /*
       ##
       _#
       _#
       */
      for (int y = 0; y <= board.length - 3; y++) {
        for (int x = 0; x <= board[0].length - 2; x++) {
          if (board[y][x + 1] == 0 && board[y][x] == 0 && board[y + 1][x + 1] == 0 && board[y + 2][x + 1] == 0) {
            //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
            board[y][x + 1] = p;
            board[y][x] = p;
            board[y + 1][x + 1] = p;
            board[y + 2][x + 1] = p;
            if (p == blocks.length) { //solution found!
              solution = Solution.copy(workunit);
              slavePaused = true;
              return;
            } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
            if (!workunit.isStupid()) {
              toAdd.add(BoardState.clone(workunit));
            }
            }
            //remove changes, keep looking
            board[y][x + 1] = 0;
            board[y][x] = 0;
            board[y + 1][x + 1] = 0;
            board[y + 2][x + 1] = 0;
          }
        }
      }
      /*
       __#
       ###
       */
      for (int y = 0; y <= board.length - 2; y++) {
        for (int x = 0; x <= board[0].length - 3; x++) {
          if (board[y + 1][x] == 0 && board[y][x + 2] == 0 && board[y + 1][x + 1] == 0 && board[y + 1][x + 2] == 0) {
            //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
            board[y + 1][x] = p;
            board[y][x + 2] = p;
            board[y + 1][x + 1] = p;
            board[y + 1][x + 2] = p;
            if (p == blocks.length) { //solution found!
              solution = Solution.copy(workunit);
              slavePaused = true;
              return;
            } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
              if (!workunit.isStupid()) {
                toAdd.add(BoardState.clone(workunit));
              }
            }
            //remove changes, keep looking
            board[y + 1][x] = 0;
            board[y][x + 2] = 0;
            board[y + 1][x + 1] = 0;
            board[y + 1][x + 2] = 0;
          }
        }
      }
      }
  
      if (block == TetrisPuzzleSolverMT.S) {
        //S shaped block can have 2 rotations
        /*
         #
         ##
         _#
         */
        for (int y = 0; y <= board.length - 3; y++) {
          for (int x = 0; x <= board[0].length - 2; x++) {
            if (board[y][x] == 0 && board[y + 1][x] == 0 && board[y + 1][x + 1] == 0 && board[y + 2][x + 1] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              board[y][x] = p;
              board[y + 1][x] = p;
              board[y + 1][x + 1] = p;
              board[y + 2][x + 1] = p;
              if (p == blocks.length) { //solution found!
                solution = Solution.copy(workunit);
                slavePaused = true;
                return;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState.clone(workunit));
                }
              }
              //remove changes, keep looking
              board[y][x] = 0;
              board[y + 1][x] = 0;
              board[y + 1][x + 1] = 0;
              board[y + 2][x + 1] = 0;
            }
          }
        }
        /*
         _##
         ##
         */
        for (int y = 0; y <= board.length - 2; y++) {
          for (int x = 0; x <= board[0].length - 3; x++) {
            if (board[y][x + 1] == 0 && board[y][x + 2] == 0 && board[y + 1][x] == 0 && board[y + 1][x + 1] == 0) {
              //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
              board[y][x + 1] = p;
              board[y][x + 2] = p;
              board[y + 1][x] = p;
              board[y + 1][x + 1] = p;
              if (p == blocks.length) { //solution found!
                solution = Solution.copy(workunit);
                slavePaused = true;
                return;
              } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
                if (!workunit.isStupid()) {
                  toAdd.add(BoardState.clone(workunit));
                }
              }
              //remove changes, keep looking
              board[y][x + 1] = 0;
              board[y][x + 2] = 0;
              board[y + 1][x] = 0;
              board[y + 1][x + 1] = 0;
            }
          }
        }
      }

      if (block == TetrisPuzzleSolverMT.Z) {
        //Z shaped block can have 2 rotations
        /*
         **
         _**
         */
      for (int y = 0; y <= board.length - 2; y++) {
        for (int x = 0; x <= board[0].length - 3; x++) {
          if (board[y][x] == 0 && board[y][x + 1] == 0 && board[y + 1][x + 1] == 0 && board[y + 1][x + 2] == 0) {
            //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
            board[y][x] = p;
            board[y][x + 1] = p;
            board[y + 1][x + 1] = p;
            board[y + 1][x + 2] = p;
            if (p == blocks.length) { //solution found!
              solution = Solution.copy(workunit);
              slavePaused = true;
              return;
            } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
              if (!workunit.isStupid()) {
                toAdd.add(BoardState.clone(workunit));
              }
            }
            //remove changes, keep looking
            board[y][x] = 0;
            board[y][x + 1] = 0;
            board[y + 1][x + 1] = 0;
            board[y + 1][x + 2] = 0;
          }
        }
      }
      /*
       _#
       ##
       #
       */
      for (int y = 0; y <= board.length - 3; y++) {
        for (int x = 0; x <= board[0].length - 2; x++) {
          if (board[y][x + 1] == 0 && board[y + 1][x] == 0 && board[y + 1][x + 1] == 0 && board[y + 2][x] == 0) {
            //we found a hole that fits this block, we'll place it here and see if the puzzle can be solved
            board[y][x + 1] = p;
            board[y + 1][x] = p;
            board[y + 1][x + 1] = p;
            board[y + 2][x] = p;
            if (p == blocks.length) { //solution found!
              solution = Solution.copy(workunit);
              slavePaused = true;
              return;
            } else { //needs more work. add to new state to work queue, but only if it's not a stupid config
              if (!workunit.isStupid()) {
                toAdd.add(BoardState.clone(workunit));
              }
            }
            //remove changes, keep looking
            board[y][x + 1] = 0;
            board[y + 1][x] = 0;
            board[y + 1][x + 1] = 0;
            board[y + 2][x] = 0;
          }
        }
      }
    }

      if (toAdd.isNotEmpty) { //we got work to add to the main queue
        //synchronized (queue) {
          queue.addAll(toAdd);
        //}
      }
    }

  }
}
