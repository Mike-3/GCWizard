import '../declaration.dart';
import '../decompiler.dart';
import '../output.dart';
import 'expression.dart';

class LocalVariable extends Expression {
  final Declaration decl;

  LocalVariable(this.decl) : super(PRECEDENCE_ATOMIC);

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
    out.print(decl.name);
  }

  @override
  bool isBrief() {
    return true;
  }
}
