import '../expression/expression.dart';
import '../expression/unaryexpression.dart';
import '../registers.dart';
import 'branch.dart';

class NotBranch extends Branch {
  final Branch branch;

  NotBranch(this.branch) : super(branch.line, branch.begin, branch.end);

  @override
  Branch invert() {
    return branch;
  }

  @override
  int getRegister() {
    return branch.getRegister();
  }

  @override
  Expression asExpression(Registers r) {
    return UnaryExpression("not ", branch.asExpression(r), Expression.PRECEDENCE_UNARY);
  }

  @override
  void useExpression(Expression expression) {
    // Do nothing
  }
}