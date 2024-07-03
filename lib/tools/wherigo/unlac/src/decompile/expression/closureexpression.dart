import '../../parse/lfunction.dart';
import '../declaration.dart';
import '../decompiler.dart';
import '../output.dart';
import '../target/tabletarget.dart';
import '../target/target.dart';
import '../target/variabletarget.dart';
import 'expression.dart';

class ClosureExpression extends Expression {
  final LFunction function;
  int upvalueLine;
  List<Declaration> declList;

  ClosureExpression(this.function, this.declList, this.upvalueLine) : super(Expression.PRECEDENCE_ATOMIC);

  int getConstantIndex() {
    return -1;
  }

  @override
  bool isClosure() {
    return true;
  }

  @override
  bool isUngrouped() {
    return true;
  }

  @override
  bool isUpvalueOf(int register) {
    /*
    if(function.header.version == 0x51) {
      return false; //TODO:
    }
    */
    for (var upvalue in function.upvalues) {
      if (upvalue.instack && upvalue.idx == register) {
        return true;
      }
    }
    return false;
  }

  @override
  int closureUpvalueLine() {
    return upvalueLine;
  }

  @override
  void print(Decompiler outer, Output out) {
    var d = Decompiler(function, outer.declList, upvalueLine);
    out.print('function');
    printMain(out, d, true);
  }

  @override
  void printClosure(Decompiler outer, Output out, Target name) {
    var d = Decompiler(function, outer.declList, upvalueLine);
    out.print('function ');
    if (function.numParams >= 1 && d.declList[0].name == 'self' && name is TableTarget) {
      name.printMethod(outer, out);
      printMain(out, d, false);
    } else {
      name.print(outer, out);
      printMain(out, d, true);
    }
  }

  void printMain(Output out, Decompiler d, bool includeFirst) {
    out.print('(');
    int start = includeFirst ? 0 : 1;
    if (function.numParams > start) {
      VariableTarget(d.declList[start]).print(d, out);
      for (int i = start + 1; i < function.numParams; i++) {
        out.print(', ');
        VariableTarget(d.declList[i]).print(d, out);
      }
    }
    if ((function.vararg & 1) == 1) {
      if (function.numParams > start) {
        out.print(', ...');
      } else {
        out.print('...');
      }
    }
    out.print(')');
    out.println();
    out.indent();
    d.decompile();
    d.print(out);
    out.dedent();
    out.print('end');
    //out.println(); //This is an extra space for formatting
  }
}