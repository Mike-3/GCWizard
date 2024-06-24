import '../decompiler.dart';
import '../output.dart';
import 'expression.dart';

class GlobalExpression extends Expression {
  final String name;
  final int index;

  GlobalExpression(this.name, this.index) : super(PRECEDENCE_ATOMIC);

  @override
  int getConstantIndex() {
    return index;
  }

  @override
  bool isDotChain() {
    return true;
  }

  @override
  void print(Decompiler d, Output out) {
    out.print(name);
  }

  @override
  bool isBrief() {
    return true;
  }
}