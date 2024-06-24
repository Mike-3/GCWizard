import 'package:unluac/decompile/decompiler.dart';
import 'package:unluac/decompile/output.dart';
import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/branch/branch.dart';
import 'package:unluac/decompile/statement/statement.dart';
import 'package:unluac/parse/lfunction.dart';

class IfThenElseBlock extends Block {
  final Branch branch;
  final int loopback;
  final Registers r;
  final List<Statement> statements;
  final bool emptyElse;
  ElseEndBlock partner;

  IfThenElseBlock(LFunction function, this.branch, this.loopback, this.emptyElse, this.r)
      : statements = List<Statement>.filled(branch.end - branch.begin + 1, null, growable: true),
        super(function, branch.begin, branch.end);

  @override
  int compareTo(Block block) {
    if (block == partner) {
      return -1;
    } else {
      return super.compareTo(block);
    }
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
  void addStatement(Statement statement) {
    statements.add(statement);
  }

  @override
  int scopeEnd() {
    return end - 2;
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
    out.print('if ');
    branch.asExpression(r).print(d, out);
    out.print(' then');
    out.println();
    out.indent();
    // Handle the case where the "then" is empty in if-then-else.
    // The jump over the else block is falsely detected as a break.
    if (statements.length == 1 && statements[0] is Break) {
      Break b = statements[0] as Break;
      if (b.target == loopback) {
        out.dedent();
        return;
      }
    }
    Statement.printSequence(d, out, statements);
    out.dedent();
    if (emptyElse) {
      out.println('else');
      out.println('end');
    }
  }
}