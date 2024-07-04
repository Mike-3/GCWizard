import '../../parse/lfunction.dart';
import '../decompiler.dart';
import '../output.dart';
import '../statement/statement.dart';
import 'block.dart';

class AlwaysLoop extends Block {
  final List<Statement> statements;

  AlwaysLoop(LFunction function, int begin, int end)
      : statements = <Statement>[],
        super(function, begin, end);

  @override
  int scopeEnd() {
    return end - 2;
  }

  @override
  bool breakable() {
    return true;
  }

  @override
  bool isContainer() {
    return true;
  }

  @override
  bool isUnprotected() {
    return true;
  }

  @override
  int getLoopback() {
    return begin;
  }

  @override
  void print(Decompiler d, Output out) {
    out.printlnWithText("while true do");
    out.indent();
    Statement.printSequence(d, out, statements);
    out.dedent();
    out.print("end");
  }

  @override
  void addStatement(Statement statement) {
    statements.add(statement);
  }
}