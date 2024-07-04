import '../../parse/lfunction.dart';
import '../branch/branch.dart';
import '../decompiler.dart';
import '../operation/operation.dart';
import '../operation/registerset.dart';
import '../output.dart';
import '../registers.dart';
import '../statement/statement.dart';
import 'block.dart';

class CompareBlock extends Block {
  int target;
  Branch branch;

  CompareBlock(LFunction function, int begin, int end, this.target, this.branch) 
      : super(function, begin, end);

  @override
  bool isContainer() {
    return false;
  }

  @override
  bool breakable() {
    return false;
  }

  @override
  void addStatement(Statement statement) {
    // Do nothing
  }

  @override
  bool isUnprotected() {
    return false;
  }

  @override
  int getLoopback() {
    throw StateError('Illegal state');
  }

  @override
  void print(Decompiler d, Output out) {
    out.print('-- unhandled compare assign');
  }

  @override
  Operation process(Decompiler d) {
    return Operation(end - 1, (Registers r, Block block) {
      return RegisterSet(end - 1, target, branch.asExpression(r)).process(r, block);
    });
  }
}