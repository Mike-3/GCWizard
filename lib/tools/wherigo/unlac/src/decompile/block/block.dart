import '../../parse/lfunction.dart';
import '../decompiler.dart';
import '../operation/operation.dart';
import '../registers.dart';
import '../statement/statement.dart';

abstract class Block extends Statement implements Comparable<Block> {
  final LFunction function;
  int begin;
  int end;
  bool loopRedirectAdjustment = false;

  Block(this.function, this.begin, this.end);

  void addStatement(Statement statement);

  bool contains(Block block) {
    return begin <= block.begin && end >= block.end;
  }

  bool containsLine(int line) {
    return begin <= line && line < end;
  }

  int scopeEnd() {
    return end - 1;
  }

  /// An unprotected block is one that ends in a JMP instruction.
  /// If this is the case, any inner statement that tries to jump
  /// to the end of this block will be redirected.
  ///
  /// (One of the lua compiler's few optimizations is that it changes
  /// any JMP that targets another JMP to the ultimate target. This
  /// is what I call redirection.)
  bool isUnprotected();

  int getLoopback();

  bool breakable();

  bool isContainer();

  @override
  int compareTo(Block other) {
    if (begin < other.begin) {
      return -1;
    } else if (begin == other.begin) {
      if (end < other.end) {
        return 1;
      } else if (end == other.end) {
        if (isContainer() && !other.isContainer()) {
          return -1;
        } else if (!isContainer() && other.isContainer()) {
          return 1;
        } else {
          return 0;
        }
      } else {
        return -1;
      }
    } else {
      return 1;
    }
  }

  Operation process(Decompiler d) {
    final statement = this;
    return Operation(end - 1, (Registers r, Block block) => statement);
  }
}