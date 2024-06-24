import '../decompiler.dart';
import '../output.dart';
import 'expression.dart';

class UpvalueExpression extends Expression {
  final String name;

  UpvalueExpression(this.name) : super(PRECEDENCE_ATOMIC);

  @override
  int getConstantIndex() {
    return -1;
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

  @override
  bool isEnvironmentTable(Decompiler d) {
    return d.getVersion().isEnvironmentTable(name);
  }
}