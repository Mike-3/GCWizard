import '../../parse/lfunction.dart';
import '../../version.dart';
import '../decompiler.dart';
import '../expression/expression.dart';
import '../output.dart';
import '../registers.dart';
import '../statement/statement.dart';
import 'block.dart';

class TForBlock extends Block {
  final int register;
  final int length;
  final Registers r;
  final List<Statement> statements;

  TForBlock(LFunction function, int begin, int end, int register, int length, Registers r)
      : this.register = register,
        this.length = length,
        this.r = r,
        statements = List<Statement>.filled(end - begin + 1, Statement()),
        super(function, begin, end);

  @override
  int scopeEnd() {
    return end - 3;
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
    return false;
  }

  @override
  int getLoopback() {
    throw StateError('Illegal state');
  }

  @override
  void print(Decompiler d, Output out) {
    out.print('for ');
    if (function.header.version == Version.LUA50) {
      r.getTarget(register + 2, begin - 1).print(d, out);
      for (int r1 = register + 3; r1 <= register + 2 + length; r1++) {
        out.print(', ');
        r.getTarget(r1, begin - 1).print(d, out);
      }
    } else {
      r.getTarget(register + 3, begin - 1).print(d, out);
      for (int r1 = register + 4; r1 <= register + 2 + length; r1++) {
        out.print(', ');
        r.getTarget(r1, begin - 1).print(d, out);
      }
    }
    out.print(' in ');
    Expression value;
    value = r.getValue(register, begin - 1);
    value.print(d, out);
    if (!value.isMultiple()) {
      out.print(', ');
      value = r.getValue(register + 1, begin - 1);
      value.print(d, out);
      if (!value.isMultiple()) {
        out.print(', ');
        value = r.getValue(register + 2, begin - 1);
        value.print(d, out);
      }
    }
    out.print(' do');
    out.println();
    out.indent();
    Statement.printSequence(d, out, statements);
    out.dedent();
    out.print('end');
  }
}