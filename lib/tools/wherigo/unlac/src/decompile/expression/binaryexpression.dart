import '../decompiler.dart';
import '../output.dart';
import 'expression.dart';

class BinaryExpression extends Expression {
  final String op;
  final Expression left;
  final Expression right;
  final int associativity;

  BinaryExpression(this.op, this.left, this.right, int precedence, this.associativity) : super(precedence);

  @override
  bool isUngrouped() {
    return !beginsWithParen();
  }

  @override
  int getConstantIndex() {
    return left.getConstantIndex().compareTo(right.getConstantIndex()) > 0 ? left.getConstantIndex() : right.getConstantIndex();
  }

  @override
  bool beginsWithParen() {
    return leftGroup() || left.beginsWithParen();
  }

  @override
  void print(Decompiler d, Output out) {
    final bool leftGroup = this.leftGroup();
    final bool rightGroup = this.rightGroup();
    if (leftGroup) out.print("(");
    left.print(d, out);
    if (leftGroup) out.print(")");
    out.print(" ");
    out.print(op);
    out.print(" ");
    if (rightGroup) out.print("(");
    right.print(d, out);
    if (rightGroup) out.print(")");
  }

  bool leftGroup() {
    return precedence > left.precedence || (precedence == left.precedence && associativity == ASSOCIATIVITY_RIGHT);
  }

  bool rightGroup() {
    return precedence > right.precedence || (precedence == right.precedence && associativity == ASSOCIATIVITY_LEFT);
  }
}
