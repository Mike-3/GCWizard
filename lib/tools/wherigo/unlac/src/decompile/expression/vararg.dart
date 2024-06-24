import '../decompiler.dart';
import '../output.dart';
import 'expression.dart';

class Vararg extends Expression {
  final int length;
  final bool multiple;

  Vararg(this.length, this.multiple) : super(PRECEDENCE_ATOMIC);

  @override
  int getConstantIndex() {
    return -1;
  }

  @override
  void print(Decompiler d, Output out) {
    out.print(multiple ? "..." : "(...)");
  }

  @override
  void printMultiple(Decompiler d, Output out) {
    out.print(multiple ? "..." : "(...)");
  }

  @override
  bool isMultiple() {
    return multiple;
  }
}