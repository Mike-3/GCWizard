import '../../parse/lnil.dart';
import '../constant.dart';
import '../decompiler.dart';
import '../output.dart';
import '../target/target.dart';
import 'binaryexpression.dart';
import 'constantexpression.dart';
import 'tableliteral.dart';
import 'unaryexpression.dart';

abstract class Expression {
  static const int PRECEDENCE_OR = 1;
  static const int PRECEDENCE_AND = 2;
  static const int PRECEDENCE_COMPARE = 3;
  static const int PRECEDENCE_BOR = 4;
  static const int PRECEDENCE_BXOR = 5;
  static const int PRECEDENCE_BAND = 6;
  static const int PRECEDENCE_SHIFT = 7;
  static const int PRECEDENCE_CONCAT = 8;
  static const int PRECEDENCE_ADD = 9;
  static const int PRECEDENCE_MUL = 10;
  static const int PRECEDENCE_UNARY = 11;
  static const int PRECEDENCE_POW = 12;
  static const int PRECEDENCE_ATOMIC = 13;

  static const int ASSOCIATIVITY_NONE = 0;
  static const int ASSOCIATIVITY_LEFT = 1;
  static const int ASSOCIATIVITY_RIGHT = 2;

  static final Expression nil = ConstantExpression(Constant(LNil.NIL), -1);

  static BinaryExpression makeCONCAT(Expression left, Expression right) {
    return BinaryExpression('..',
        left, right, PRECEDENCE_CONCAT, ASSOCIATIVITY_RIGHT);
  }

  static BinaryExpression makeADD(Expression left, Expression right) {
    return BinaryExpression('+', left, right, PRECEDENCE_ADD, ASSOCIATIVITY_LEFT);
  }

  static BinaryExpression makeSUB(Expression left, Expression right) {
    return BinaryExpression('-', left, right, PRECEDENCE_ADD, ASSOCIATIVITY_LEFT);
  }

  static BinaryExpression makeMUL(Expression left, Expression right) {
    return BinaryExpression('*', left, right, PRECEDENCE_ADD, ASSOCIATIVITY_LEFT);
  }

  static BinaryExpression makeDIV(Expression left, Expression right) {
    return BinaryExpression('/', left, right, PRECEDENCE_MUL, ASSOCIATIVITY_LEFT);
  }

  static BinaryExpression makeMOD(Expression left, Expression right) {
    return BinaryExpression('%', left, right, PRECEDENCE_MUL, ASSOCIATIVITY_LEFT);
  }

  static UnaryExpression makeUNM(Expression expression) {
    return UnaryExpression('-', expression, PRECEDENCE_UNARY);
  }

  static UnaryExpression makeNOT(Expression expression) {
    return UnaryExpression('not ', expression, PRECEDENCE_UNARY);
  }

  static UnaryExpression makeLEN(Expression expression) {
    return UnaryExpression('#', expression, PRECEDENCE_UNARY);
  }

  static BinaryExpression makePOW(Expression left, Expression right) {
    return BinaryExpression('^', left, right, PRECEDENCE_POW, ASSOCIATIVITY_RIGHT);
  }

  static BinaryExpression makeIDIV(Expression left, Expression right) {
    return BinaryExpression('//', left, right, PRECEDENCE_MUL, ASSOCIATIVITY_LEFT);
  }

  static BinaryExpression makeBAND(Expression left, Expression right) {
    return BinaryExpression('&', left, right, PRECEDENCE_BAND, ASSOCIATIVITY_LEFT);
  }

  static BinaryExpression makeBOR(Expression left, Expression right) {
    return BinaryExpression('|', left, right, PRECEDENCE_BOR, ASSOCIATIVITY_LEFT);
  }

  static BinaryExpression makeBXOR(Expression left, Expression right) {
    return BinaryExpression('~', left, right, PRECEDENCE_BXOR, ASSOCIATIVITY_LEFT);
  }

  static BinaryExpression makeSHL(Expression left, Expression right) {
    return BinaryExpression('<<', left, right, PRECEDENCE_SHIFT, ASSOCIATIVITY_LEFT);
  }

  static BinaryExpression makeSHR(Expression left, Expression right) {
    return BinaryExpression('>>', left, right, PRECEDENCE_SHIFT, ASSOCIATIVITY_LEFT);
  }

  static UnaryExpression makeBNOT(Expression expression) {
    return UnaryExpression('~', expression, PRECEDENCE_UNARY);
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

  void addEntry(Entry entry) {
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