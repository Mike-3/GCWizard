import 'dart:core';
import 'declaration.dart';
import 'expression/expression.dart';
import 'expression/localvariable.dart';

class Registers {
  final int registers;
  final int length;

  final List<List<Declaration?>> decls;
  final Function f;
  final List<List<Expression?>> values;
  final List<List<int>> updated;
  final List<bool> startedLines;

  Registers(int registers, int length, List<Declaration> declList, this.f)
      : registers = registers,
        length = length,
        decls = List.generate(registers, (_) => List.filled(length + 1, null)),
        values = List.generate(registers, (_) => List.filled(length + 1, Expression.nil)),
        updated = List.generate(registers, (_) => List.filled(length + 1, 0)),
        startedLines = List.filled(length + 1, false) {
    for (var decl in declList) {
      int register = 0;
      while (decls[register][decl.begin] != null) {
        register++;
      }
      decl.register = register;
      for (int line = decl.begin; line <= decl.end; line++) {
        decls[register][line] = decl;
      }
    }
  }

  bool isAssignable(int register, int line) {
    return isLocal(register, line) && !decls[register][line]!.forLoop;
  }

  bool isLocal(int register, int line) {
    if (register < 0) return false;
    return decls[register][line] != null;
  }

  bool isNewLocal(int register, int line) {
    var decl = decls[register][line];
    return decl != null && decl.begin == line && !decl.forLoop;
  }

  List<Declaration> getNewLocals(int line) {
    var locals = <Declaration>[];
    for (int register = 0; register < registers; register++) {
      if (isNewLocal(register, line)) {
        locals.add(getDeclaration(register, line)!);
      }
    }
    return locals;
  }

  Declaration? getDeclaration(int register, int line) {
    return decls[register][line];
  }

  void startLine(int line) {
    startedLines[line] = true;
    for (int register = 0; register < registers; register++) {
      values[register][line] = values[register][line - 1];
      updated[register][line] = updated[register][line - 1];
    }
  }

  Expression getExpression(int register, int line) {
    if (isLocal(register, line - 1)) {
      return LocalVariable(getDeclaration(register, line - 1)!);
    } else {
      return values[register][line - 1]!;
    }
  }

  Expression getKExpression(int register, int line) {
    if (f.isConstant(register)) {
      return f.getConstantExpression(f.constantIndex(register));
    } else {
      return getExpression(register, line);
    }
  }

  Expression getValue(int register, int line) {
    return values[register][line - 1]!;
  }

  int getUpdated(int register, int line) {
    return updated[register][line];
  }

  void setValue(int register, int line, Expression expression) {
    values[register][line] = expression;
    updated[register][line] = line;
  }

  Target getTarget(int register, int line) {
    if (!isLocal(register, line)) {
      throw StateError("No declaration exists in register $register at line $line");
    }
    return VariableTarget(decls[register][line]!);
  }

  void setInternalLoopVariable(int register, int begin, int end) {
    var decl = getDeclaration(register, begin);
    if (decl == null) {
      decl = Declaration("_FOR_", begin, end);
      decl.register = register;
      newDeclaration(decl, register, begin, end);
    }
    decl.forLoop = true;
  }

  void setExplicitLoopVariable(int register, int begin, int end) {
    var decl = getDeclaration(register, begin);
    if (decl == null) {
      decl = Declaration("_FORV_$register_", begin, end);
      decl.register = register;
      newDeclaration(decl, register, begin, end);
    }
    decl.forLoopExplicit = true;
  }

  void newDeclaration(Declaration decl, int register, int begin, int end) {
    for (int line = begin; line <= end; line++) {
      decls[register][line] = decl;
    }
  }
}


