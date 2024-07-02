import 'dart:math';

import '../decompiler.dart';
import '../output.dart';
import 'expression.dart';

class FunctionCall extends Expression {
  final Expression function;
  final List<Expression> arguments;
  final bool multiple;

  FunctionCall(this.function, this.arguments, this.multiple) : super(Expression.PRECEDENCE_ATOMIC);

  @override
  int getConstantIndex() {
    int index = function.getConstantIndex();
    for (var argument in arguments) {
      index = max(argument.getConstantIndex(), index);
    }
    return index;
  }

  @override
  bool isMultiple() {
    return multiple;
  }

  @override
  void printMultiple(Decompiler d, Output out) {
    if (!multiple) {
      out.print("(");
    }
    print(d, out);
    if (!multiple) {
      out.print(")");
    }
  }

  bool isMethodCall() {
    return function.isMemberAccess() && arguments.isNotEmpty && function.getTable() == arguments[0];
  }

  @override
  bool beginsWithParen() {
    if (isMethodCall()) {
      var obj = function.getTable();
      return obj.isUngrouped() || obj.beginsWithParen();
    } else {
      return function.isUngrouped() || function.beginsWithParen();
    }
  }

  @override
  void print(Decompiler d, Output out) {
    var args = <Expression>[];
    if (isMethodCall()) {
      var obj = function.getTable();
      if (obj.isUngrouped()) {
        out.print("(");
        obj.print(d, out);
        out.print(")");
      } else {
        obj.print(d, out);
      }
      out.print(":");
      out.print(function.getField());
      for (var i = 1; i < arguments.length; i++) {
        args.add(arguments[i]);
      }
    } else {
      if (function.isUngrouped()) {
        out.print("(");
        function.print(d, out);
        out.print(")");
      } else {
        function.print(d, out);
      }
      for (var i = 0; i < arguments.length; i++) {
        args.add(arguments[i]);
      }
    }
    out.print("(");
    Expression.printSequence(d, out, args, false, true);
    out.print(")");
  }
}