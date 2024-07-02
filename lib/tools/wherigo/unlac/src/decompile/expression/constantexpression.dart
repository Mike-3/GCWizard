import '../constant.dart';
import '../decompiler.dart';
import '../output.dart';
import 'expression.dart';

class ConstantExpression extends Expression {
  final Constant constant;
  final int index;

  ConstantExpression(this.constant, this.index) : super(Expression.PRECEDENCE_ATOMIC);

  int getConstantIndex() {
    return index;
  }

  @override
  void print(Decompiler d, Output out) {
    constant.print(d, out, false);
  }

  @override
  void printBraced(Decompiler d, Output out) {
    constant.print(d, out, true);
  }

  @override
  bool isConstant() {
    return true;
  }

  @override
  bool isUngrouped() {
    return true;
  }

  @override
  bool isNil() {
    return constant.isNil();
  }

  @override
  bool isBoolean() {
    return constant.isBoolean();
  }

  @override
  bool isInteger() {
    return constant.isInteger();
  }

  @override
  int asInteger() {
    return constant.asInteger();
  }

  @override
  bool isString() {
    return constant.isString();
  }

  @override
  bool isIdentifier() {
    return constant.isIdentifier();
  }

  @override
  String asName() {
    return constant.asName();
  }

  @override
  bool isBrief() {
    return !constant.isString() || constant.asName().length <= 10;
  }
}