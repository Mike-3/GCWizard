import '../expression/expression.dart';
import '../registers.dart';
import 'branch.dart';
import 'notbranch.dart';

class TestNode extends Branch {
  final int test;
  final bool _invert;

  TestNode(this.test, this._invert, int line, int begin, int end)
      : super(line, begin, end) {
    isTest = true;
  }

  @override
  Branch invert() {
    return TestNode(test, !_invert, line, end, begin);
  }

  @override
  int getRegister() {
    return test;
  }

  @override
  Expression asExpression(Registers r) {
    if (_invert) {
      return NotBranch(invert()).asExpression(r);
    } else {
      return r.getExpression(test, line);
    }
  }

  @override
  void useExpression(Expression expression) {
    // Do nothing
  }

  @override
  String toString() {
    return 'TestNode[test=$test;invert=$_invert;line=$line;begin=$begin;end=$end]';
  }
}