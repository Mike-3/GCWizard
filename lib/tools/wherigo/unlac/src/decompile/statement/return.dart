import '../decompiler.dart';
import '../expression/expression.dart';
import '../output.dart';

class Return extends Statement {
  List<Expression> values;

  Return() : values = [];

  Return.single(Expression value) : values = [value];

  Return.multiple(this.values);

  @override
  void print(Decompiler d, Output out) {
    out.print('do ');
    printTail(d, out);
    out.print(' end');
  }

  @override
  void printTail(Decompiler d, Output out) {
    out.print('return');
    if (values.isNotEmpty) {
      out.print(' ');
      Expression.printSequence(d, out, values, false, true);
    }
  }
}