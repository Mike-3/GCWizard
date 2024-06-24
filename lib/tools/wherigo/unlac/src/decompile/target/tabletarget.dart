import 'decompiler.dart';
import 'output.dart';
import 'expression.dart';
import 'table_reference.dart';

class TableTarget extends Target {
  final Expression table;
  final Expression index;

  TableTarget(this.table, this.index);

  @override
  void print(Decompiler d, Output out) {
    TableReference(table, index).print(d, out);
  }

  @override
  void printMethod(Decompiler d, Output out) {
    table.print(d, out);
    out.print(":");
    out.print(index.asName());
  }

  @override
  bool isFunctionName() {
    if (!index.isIdentifier()) {
      return false;
    }
    if (!table.isDotChain()) {
      return false;
    }
    return true;
  }

  @override
  bool beginsWithParen() {
    return table.isUngrouped() || table.beginsWithParen();
  }
}


