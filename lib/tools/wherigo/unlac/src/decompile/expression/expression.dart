import '../../parse/lnil.dart';
import '../constant.dart';
import '../decompiler.dart';
import '../output.dart';
import 'binaryexpression.dart';
import 'constantexpression.dart';
import 'unaryexpression.dart';

abstract class Expression {
  static const int precedenceOr = 1;
  static const int precedenceAnd = 2;
  static const int precedenceCompare = 3;
  static const int precedenceBor = 4;
  static const int precedenceBxor = 5;
  static const int precedenceBand = 6;
  static const int precedenceShift = 7;
  static const int precedenceConcat = 8;
  static const int precedenceAdd = 9;
  static const int precedenceMul = 10;
  static const int precedenceUnary = 11;
  static const int precedencePow = 12;
  static const int precedenceAtomic = 13;

  static const int associativityNone = 0;
  static const int associativityLeft = 1;
  static const int associativityRight = 2;

  static final Expression nil = ConstantExpression(Constant(LNil.nil), -1);

  static BinaryExpression makeCONCAT(Expression left, Expression right) {
    return BinaryExpression('..',
        left, right, precedenceConcat, associativityRight);
  }

  static BinaryExpression makeADD(Expression left, Expression right) {
    return BinaryExpression('+', left, right, precedenceAdd, associativityLeft);
  }

  static BinaryExpression makeSUB(Expression left, Expression right) {
    return BinaryExpression('-', left, right, precedenceAdd, associativityLeft);
  }

  static BinaryExpression makeMUL(Expression left, Expression right) {
    return BinaryExpression('*', left, right, precedenceMul, associativityLeft);
  }

  static BinaryExpression makeDIV(Expression left, Expression right) {
    return BinaryExpression('/', left, right, precedenceMul, associativityLeft);
  }

  static BinaryExpression makeMOD(Expression left, Expression right) {
    return BinaryExpression('%', left, right, precedenceMul, associativityLeft);
  }

  static UnaryExpression makeUNM(Expression expression) {
    return UnaryExpression('-', expression, precedenceUnary);
  }

  static UnaryExpression makeNOT(Expression expression) {
    return UnaryExpression('not ', expression, precedenceUnary);
  }

  static UnaryExpression makeLEN(Expression expression) {
    return UnaryExpression('#', expression, precedenceUnary);
  }

  static BinaryExpression makePOW(Expression left, Expression right) {
    return BinaryExpression('^', left, right, precedencePow, associativityRight);
  }

  static BinaryExpression makeIDIV(Expression left, Expression right) {
    return BinaryExpression('//', left, right, precedenceMul, associativityLeft);
  }

  static BinaryExpression makeBAND(Expression left, Expression right) {
    return BinaryExpression('&', left, right, precedenceBand, associativityLeft);
  }

  static BinaryExpression makeBOR(Expression left, Expression right) {
    return BinaryExpression('|', left, right, precedenceBor, associativityLeft);
  }

  static BinaryExpression makeBXOR(Expression left, Expression right) {
    return BinaryExpression('~', left, right, precedenceBxor, associativityLeft);
  }

  static BinaryExpression makeSHL(Expression left, Expression right) {
    return BinaryExpression('<<', left, right, precedenceShift, associativityLeft);
  }

  static BinaryExpression makeSHR(Expression left, Expression right) {
    return BinaryExpression('>>', left, right, precedenceShift, associativityLeft);
  }

  static UnaryExpression makeBNOT(Expression expression) {
    return UnaryExpression('~', expression, precedenceUnary);
  }

  static void printSequence(Decompiler d, Output out, List<Expression> exprs,
      bool linebreak, bool multiple) {
    final n = exprs.length;
    for (int i = 0; i < n; i++) {
      final expr = exprs[i];
      final last = (i == n - 1) || expr.isMultiple();
      if (last) {
        if (multiple) {
          expr.printMultiple(d, out);
        } else {
          expr.print(d, out);
        }
        break;
      } else {
        expr.print(d, out);
        out.print(',');
        if (linebreak) {
          out.println();
        } else {
          out.print(' ');
        }
      }
    }
  }

  final int precedence;

  Expression(this.precedence);

  static void printUnary(Decompiler d, Output out, String op, Expression expression) {
    out.print(op);
    expression.print(d, out);
  }

  static void printBinary(Decompiler d, Output out, String op, Expression left, Expression right) {
    left.print(d, out);
    out.print(' ');
    out.print(op);
    out.print(' ');
    right.print(d, out);
  }

  void print(Decompiler d, Output out);

  void printBraced(Decompiler d, Output out) {
    print(d, out);
  }

  void printMultiple(Decompiler d, Output out) {
    print(d, out);
  }

  int getConstantIndex();

  bool beginsWithParen() {
    return false;
  }

  bool isNil() {
    return false;
  }

  bool isClosure() {
    return false;
  }

  bool isConstant() {
    return false;
  }

  bool isUngrouped() {
    return false;
  }

  bool isUpvalueOf(int register) {
    throw UnsupportedError('Only supported for closures');
  }

  bool isBoolean() {
    return false;
  }

  bool isInteger() {
    return false;
  }

  int asInteger() {
    throw UnsupportedError('Not an integer');
  }

  bool isString() {
    return false;
  }

  bool isIdentifier() {
    return false;
  }

  bool isDotChain() {
    return false;
  }

  int closureUpvalueLine() {
    throw UnsupportedError('Not a closure');
  }

  void printClosure(Decompiler d, Output out, Target name) {
    throw UnsupportedError('Not a closure');
  }

  String asName() {
    throw UnsupportedError('Not a name');
  }

  bool isTableLiteral() {
    return false;
  }

  bool isNewEntryAllowed() {
    throw UnsupportedError('Not a table literal');
  }

  void addEntry(TableLiteral.Entry entry) {
    throw UnsupportedError('Not a table literal');
  }

  bool isMultiple() {
    return false;
  }

  bool isMemberAccess() {
    return false;
  }

  Expression getTable() {
    throw UnsupportedError('Not a member access');
  }

  String getField() {
    throw UnsupportedError('Not a member access');
  }

  bool isBrief() {
    return false;
  }

  bool isEnvironmentTable(Decompiler d) {
    return false;
  }
}