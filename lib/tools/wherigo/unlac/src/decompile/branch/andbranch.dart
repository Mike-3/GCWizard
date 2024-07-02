import '../expression/binaryexpression.dart';
import '../expression/expression.dart';
import '../registers.dart';
import 'branch.dart';
import 'orbranch.dart';

class AndBranch extends Branch {
  final Branch left;
  final Branch right;

  AndBranch(this.left, this.right) : super(right.line, right.begin, right.end);

  @override
  Branch invert() {
    return OrBranch(left.invert(), right.invert());
  }

  /*
  @override
  Branch invert() {
    return NotBranch(OrBranch(left.invert(), right.invert()));
  }
  */

  @override
  int getRegister() {
    int rleft = left.getRegister();
    int rright = right.getRegister();
    return rleft == rright ? rleft : -1;
  }

  @override
  Expression asExpression(Registers r) {
    return BinaryExpression("and", left.asExpression(r), right.asExpression(r), Expression.PRECEDENCE_AND, Expression.ASSOCIATIVITY_NONE);
  }

  @override
  void useExpression(Expression expression) {
    left.useExpression(expression);
    right.useExpression(expression);
  }
}