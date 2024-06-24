import 'package:unluac/decompile/decompiler.dart';
import 'package:unluac/decompile/output.dart';
import 'package:unluac/decompile/statement.dart';
import 'package:unluac/parse/lfunction.dart';

class Break extends Block {
  final int target;

  Break(LFunction function, int line, this.target) : super(function, line, line);

  @override
  void addStatement(Statement statement) {
    throw StateError('Illegal state');
  }

  @override
  bool isContainer() {
    return false;
  }

  @override
  bool breakable() {
    return false;
  }

  @override
  bool isUnprotected() {
    // Actually, it is unprotected, but not really a block
    return false;
  }

  @override
  int getLoopback() {
    throw StateError('Illegal state');
  }

  @override
  void print(Decompiler d, Output out) {
    out.print('do break end');
  }

  @override
  void printTail(Decompiler d, Output out) {
    out.print('break');
  }
}