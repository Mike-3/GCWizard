import 'package:unluac/decompile/decompiler.dart';
import 'package:unluac/decompile/output.dart';
import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/branch/branch.dart';
import 'package:unluac/decompile/statement/statement.dart';
import 'package:unluac/parse/lfunction.dart';

class WhileBlock extends Block {
  final Branch branch;
  final int loopback;
  final Registers r;
  final List<Statement> statements;

  WhileBlock(LFunction function, Branch branch, int loopback, Registers r)
      : branch = branch,
        loopback = loopback,
        r = r,
        statements = List<Statement>.filled(branch.end - branch.begin + 1, Statement(), growable: true),
        super(function, branch.begin, branch.end);

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
  void addStatement(Statement statement) {
    statements.add(statement);
  }

  @override
  bool isUnprotected() {
    return true;
  }

  @override
  int getLoopback() {
    return loopback;
  }

  @override
  void print(Decompiler d, Output out) {
    out.print('while ');
    branch.asExpression(r).print(d, out);
    out.print(' do');
    out.println();
    out.indent();
    Statement.printSequence(d, out, statements);
    out.dedent();
    out.print('end');
  }
}