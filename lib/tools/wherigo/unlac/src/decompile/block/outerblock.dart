import '../../parse/lfunction.dart';
import '../decompiler.dart';
import '../output.dart';
import '../statement/return.dart';
import '../statement/statement.dart';
import 'block.dart';

class OuterBlock extends Block {
  final List<Statement> statements;

  OuterBlock(LFunction function, int length)
      : statements = List<Statement>.filled(length, Statement(), growable: true),
        super(function, 0, length + 1);

  @override
  void addStatement(Statement statement) {
    statements.add(statement);
  }

  @override
  bool breakable() {
    return false;
  }

  @override
  bool isContainer() {
    return true;
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
  int scopeEnd() {
    return (end - 1) + function.header.version.getOuterBlockScopeAdjustment();
  }

  @override
  void print(Decompiler d, Output out) {
    /* extra return statement */
    int last = statements.length - 1;
    if (last < 0 || !(statements[last] is Return)) {
      throw StateError(statements[last].toString());
    }
    statements.removeAt(last);
    Statement.printSequence(d, out, statements);
  }
}