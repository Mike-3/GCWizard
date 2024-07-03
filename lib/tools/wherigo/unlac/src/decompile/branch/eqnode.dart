import '../expression/binaryexpression.dart';
import '../expression/expression.dart';
import '../registers.dart';
import 'branch.dart';

class EQNode extends Branch {
  final int left;
  final int right;
  final bool _invert;

  EQNode(this.left, this.right, this._invert, int line, int begin, int end)
      : super(line, begin, end);

  @override
  Branch invert() {
    return EQNode(left, right, !_invert, line, end, begin);
  }

  @override
  int getRegister() {
    return -1;
  }

  @override
  Expression asExpression(Registers r) {
    bool transpose = false;
    String op = _invert ? "!=" : "==";
    return BinaryExpression(
      op,
      r.getKExpression(!transpose ? left : right, line),
      r.getKExpression(!transpose ? right : left, line),
      Expression.PRECEDENCE_COMPARE,
      Expression.ASSOCIATIVITY_LEFT,
    );
  }

  @override
  void useExpression(Expression expression) {
    // Do nothing
  }
}