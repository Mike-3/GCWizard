import '../../parse/lboolean.dart';
import '../constant.dart';
import '../expression/constantexpression.dart';
import '../expression/expression.dart';
import '../registers.dart';
import 'branch.dart';

class TrueNode extends Branch {
  final int register;
  final bool invert;

  TrueNode(this.register, this.invert, int line, int begin, int end) : super(line, begin, end) {
    this.setTarget = register;
    // isTest = true;
  }

  @override
  Branch invert() {
    return TrueNode(register, !invert, line, end, begin);
  }

  @override
  int getRegister() {
    return register;
  }

  @override
  Expression asExpression(Registers r) {
    return ConstantExpression(Constant(invert ? LBoolean.LTRUE : LBoolean.LFALSE), -1);
  }

  @override
  void useExpression(Expression expression) {
    /* Do nothing */
  }

  @override
  String toString() {
    return 'TrueNode[invert=$invert;line=$line;begin=$begin;end=$end]';
  }
}