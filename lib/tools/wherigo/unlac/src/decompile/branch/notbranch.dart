import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/expression/expression.dart';
import 'package:unluac/decompile/expression/unary_expression.dart';

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