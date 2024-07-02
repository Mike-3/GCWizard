import '../expression/expression.dart';
import '../registers.dart';
import 'branch.dart';

class AssignNode extends Branch {
  Expression? expression;

  AssignNode(int line, int begin, int end) : super(line, begin, end);

  @override
  Branch invert() {
    throw StateError('Illegal state');
  }

  @override
  int getRegister() {
    throw StateError('Illegal state');
  }

  @override
  Expression asExpression(Registers r) {
    return expression!;
  }

  @override
  void useExpression(Expression expression) {
    this.expression = expression;
  }
}