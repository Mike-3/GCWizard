import 'package:unluac/decompile/decompiler.dart';
import 'package:unluac/decompile/output.dart';
import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/branch/branch.dart';
import 'package:unluac/decompile/statement/statement.dart';
import 'package:unluac/parse/lfunction.dart';

class RepeatBlock extends Block {
  final Branch branch;
  final Registers r;
  final List<Statement> statements;

  RepeatBlock(LFunction function, Branch branch, Registers r)
      : branch = branch,
        r = r,
        statements = List<Statement>.filled(branch.begin - branch.end + 1, Statement(), growable: true),
        super(function, branch.end, branch.begin);

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
    return false;
  }

  @override
  int getLoopback() {
    throw StateError('Illegal state');
  }

  @override
  void print(Decompiler d, Output out) {
    out.print('repeat');
    out.println();
    out.indent();
    Statement.printSequence(d, out, statements);
    out.dedent();
    out.print('until ');
    branch.asExpression(r).print(d, out);
  }
}