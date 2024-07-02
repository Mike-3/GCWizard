import '../expression/expression.dart';
import '../registers.dart';

abstract class Branch {
  final int line;
  int begin;
  int end; // Might be modified to undo redirect

  bool isSet = false;
  bool isCompareSet = false;
  bool isTest = false;
  int setTarget = -1;

  Branch(this.line, this.begin, this.end);

  Branch invert();

  int getRegister();

  Expression asExpression(Registers r);

  void useExpression(Expression expression);
}