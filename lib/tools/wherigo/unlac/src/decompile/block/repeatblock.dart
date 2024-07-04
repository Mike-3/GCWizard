import '../../parse/lfunction.dart';
import '../branch/branch.dart';
import '../decompiler.dart';
import '../output.dart';
import '../registers.dart';
import '../statement/statement.dart';
import 'block.dart';

class RepeatBlock extends Block {
  final Branch branch;
  final Registers r;
  final List<Statement> statements;

  RepeatBlock(LFunction function, Branch branch, Registers r)
      : this.branch = branch,
        this.r = r,
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