import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/expression/binary_expression.dart';
import 'package:unluac/decompile/expression/expression.dart';
import 'package:unluac/decompile/expression/unary_expression.dart';

class LTNode extends Branch {
  final int left;
  final int right;
  final bool invert;

  LTNode(this.left, this.right, this.invert, int line, int begin, int end) : super(line, begin, end);

  @override
  Branch invert() {
    return LTNode(left, right, !invert, line, end, begin);
  }

  @override
  int getRegister() {
    return -1;
  }

  @override
  Expression asExpression(Registers r) {
    bool transpose = false;
    Expression leftExpression = r.getKExpression(left, line);
    Expression rightExpression = r.getKExpression(right, line);
    if (!leftExpression.isConstant() && !rightExpression.isConstant()) {
      transpose = r.getUpdated(left, line) > r.getUpdated(right, line);
    } else {
      transpose = rightExpression.getConstantIndex() < leftExpression.getConstantIndex();
    }
    String op = !transpose ? "<" : ">";
    Expression rtn = BinaryExpression(op, !transpose ? leftExpression : rightExpression, !transpose ? rightExpression : leftExpression, Expression.PRECEDENCE_COMPARE, Expression.ASSOCIATIVITY_LEFT);
    if (invert) {
      rtn = UnaryExpression("not ", rtn, Expression.PRECEDENCE_UNARY);
    }
    return rtn;
  }

  @override
  void useExpression(Expression expression) {
    // Do nothing
  }
}