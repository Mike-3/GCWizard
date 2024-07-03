import 'dart:math';

import '../decompiler.dart';
import '../output.dart';
import 'expression.dart';

class TableReference extends Expression {
  final Expression table;
  final Expression index;

  TableReference(this.table, this.index) : super(Expression.PRECEDENCE_ATOMIC);

  @override
  int getConstantIndex() {
    return max(table.getConstantIndex(),index.getConstantIndex());
  }

  @override
  void print(Decompiler d, Output out) {
    bool isGlobal = table.isEnvironmentTable(d) && index.isIdentifier();
    if (!isGlobal) {
      if (table.isUngrouped()) {
        out.print("(");
        table.print(d, out);
        out.print(")");
      } else {
        table.print(d, out);
      }
    }
    if (index.isIdentifier()) {
      if (!isGlobal) {
        out.print(".");
      }
      out.print(index.asName());
    } else {
      out.print("[");
      index.printBraced(d, out);
      out.print("]");
    }
  }

  @override
  bool isDotChain() {
    return index.isIdentifier() && table.isDotChain();
  }

  @override
  bool isMemberAccess() {
    return index.isIdentifier();
  }

  @override
  bool beginsWithParen() {
    return table.isUngrouped() || table.beginsWithParen();
  }

  @override
  Expression getTable() {
    return table;
  }

  @override
  String getField() {
    return index.asName();
  }
}