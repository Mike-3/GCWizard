import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/expression.dart';
import 'package:unluac/decompile/branch.dart';

class TestNode extends Branch {
  final int test;
  final bool invert;

  TestNode(this.test, this.invert, int line, int begin, int end)
      : super(line, begin, end) {
    isTest = true;
  }

  @override
  Branch invert() {
    return TestNode(test, !invert, line, end, begin);
  }

  @override
  int getRegister() {
    return test;
  }

  @override
  Expression asExpression(Registers r) {
    if (invert) {
      return NotBranch(this.invert()).asExpression(r);
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
    return 'TestNode[test=$test;invert=$invert;line=$line;begin=$begin;end=$end]';
  }
}