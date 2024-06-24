import 'package:unluac/decompile/decompiler.dart';
import 'package:unluac/decompile/output.dart';
import 'package:unluac/decompile/statement.dart';
import 'package:unluac/parse/lfunction.dart';

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
    out.println('do');
    out.indent();
    Statement.printSequence(d, out, statements);
    out.dedent();
    out.print('end');
  }
}