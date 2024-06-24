import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/expression.dart';
import 'branch.dart';

class TestSetNode extends Branch {
  final int test;
  final bool invert;
  final int setTarget;

  TestSetNode(int target, this.test, this.invert, int line, int begin, int end)
      : setTarget = target,
        super(line, begin, end);

  @override
  Branch invert() {
    return TestSetNode(setTarget, test, !invert, line, end, begin);
  }

  @override
  int getRegister() {
    return setTarget;
  }

  @override
  Expression asExpression(Registers r) {
    return r.getExpression(test, line);
  }

  @override
  void useExpression(Expression expression) {
    // Do nothing
  }

  @override
  String toString() {
    return 'TestSetNode[target=$setTarget;test=$test;invert=$invert;line=$line;begin=$begin;end=$end]';
  }
}