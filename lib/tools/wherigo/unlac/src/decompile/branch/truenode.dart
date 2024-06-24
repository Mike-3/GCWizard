import 'package:unluac/decompile/constant.dart';
import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/expression/constant_expression.dart';
import 'package:unluac/decompile/expression/expression.dart';
import 'package:unluac/parse/lboolean.dart';

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