import 'package:unluac/decompile/decompiler.dart';
import 'package:unluac/decompile/output.dart';
import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/expression.dart';
import 'package:unluac/decompile/statement.dart';
import 'package:unluac/parse/lfunction.dart';
import '../version.dart';

class ForBlock extends Block {
  final int register;
  final Registers r;
  final List<Statement> statements;

  ForBlock(LFunction function, int begin, int end, int register, Registers r)
      : register = register,
        r = r,
        statements = List<Statement>.filled(end - begin + 1, Statement()),
        super(function, begin, end);

  @override
  int scopeEnd() {
    return end - 2;
  }

  @override
  void addStatement(Statement statement) {
    statements.add(statement);
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
      r.getTarget(register, begin - 1).print(d, out);
    } else {
      r.getTarget(register + 3, begin - 1).print(d, out);
    }
    out.print(' = ');
    if (function.header.version == Version.LUA50) {
      r.getValue(register, begin - 2).print(d, out);
    } else {
      r.getValue(register, begin - 1).print(d, out);
    }
    out.print(', ');
    r.getValue(register + 1, begin - 1).print(d, out);
    Expression step = r.getValue(register + 2, begin - 1);
    if (!step.isInteger() || step.asInteger() != 1) {
      out.print(', ');
      step.print(d, out);
    }
    out.print(' do');
    out.println();
    out.indent();
    Statement.printSequence(d, out, statements);
    out.dedent();
    out.print('end');
  }
}