import '../../parse/lfunction.dart';
import '../decompiler.dart';
import '../output.dart';
import '../statement/statement.dart';
import 'block.dart';

class DoEndBlock extends Block {
  final List<Statement> statements;

  DoEndBlock(LFunction function, int begin, int end)
      : statements = List<Statement>.filled(end - begin + 1, Statement(), growable: true),
        super(function, begin, end);

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
  void print(Decompiler d, Output out) {
    out.printlnWithText('do');
    out.indent();
    Statement.printSequence(d, out, statements);
    out.dedent();
    out.print('end');
  }
}