import 'package:unluac/decompile/decompiler.dart';
import 'package:unluac/decompile/op.dart';
import 'package:unluac/decompile/output.dart';
import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/branch/branch.dart';
import 'package:unluac/decompile/expression/expression.dart';
import 'package:unluac/decompile/operation/operation.dart';
import 'package:unluac/decompile/operation/register_set.dart';
import 'package:unluac/decompile/statement/assignment.dart';
import 'package:unluac/decompile/statement/statement.dart';
import 'package:unluac/decompile/target/target.dart';
import 'package:unluac/parse/l_function.dart';

class SetBlock extends Block {
  final int target;
  Assignment? assign;
  final Branch branch;
  final Registers r;
  final bool empty;
  bool finalize = false;

  SetBlock(LFunction function, this.branch, this.target, int line, int begin, int end, this.empty, this.r)
      : super(function, begin, end) {
    if (begin == end) this.begin -= 1;
  }

  @override
  void addStatement(Statement statement) {
    if (!finalize && statement is Assignment) {
      assign = statement;
    } else if (statement is BooleanIndicator) {
      finalize = true;
    }
  }

  @override
  bool isUnprotected() => false;

  @override
  int getLoopback() => throw StateError('Illegal state');

  @override
  void print(Decompiler d, Output out) {
    if (assign != null && assign!.getFirstTarget() != null) {
      var assignOut = Assignment(assign!.getFirstTarget(), getValue());
      assignOut.print(d, out);
    } else {
      out.print('-- unhandled set block');
      out.println();
    }
  }

  @override
  bool breakable() => false;

  @override
  bool isContainer() => false;

  void useAssignment(Assignment assign) {
    this.assign = assign;
    branch.useExpression(assign.getFirstValue());
  }

  Expression getValue() => branch.asExpression(r);

  @override
  Operation process(Decompiler d) {
    if (empty) {
      var expression = r.getExpression(branch.setTarget, end);
      branch.useExpression(expression);
      return RegisterSet(end - 1, branch.setTarget, branch.asExpression(r));
    } else if (assign != null) {
      branch.useExpression(assign!.getFirstValue());
      var target = assign!.getFirstTarget();
      var value = getValue();
      return Operation(end - 1, (Registers r, Block block) {
        return Assignment(target, value);
      });
    } else {
      return Operation(end - 1, (Registers r, Block block) {
        Expression? expr;
        int register = 0;
        for (; register < r.registers; register++) {
          if (r.getUpdated(register, branch.end - 1) == branch.end - 1) {
            expr = r.getValue(register, branch.end);
            break;
          }
        }
        if (d.code.op(branch.end - 2) == Op.LOADBOOL && d.code.C(branch.end - 2) != 0) {
          int target = d.code.A(branch.end - 2);
          if (d.code.op(branch.end - 3) == Op.JMP && d.code.sBx(branch.end - 3) == 2) {
            expr = r.getValue(target, branch.end - 2);
          } else {
            expr = r.getValue(target, branch.begin);
          }
          branch.useExpression(expr);
          if (r.isLocal(target, branch.end - 1)) {
            return Assignment(r.getTarget(target, branch.end - 1), branch.asExpression(r));
          }
          r.setValue(target, branch.end - 1, branch.asExpression(r));
        } else if (expr != null && target >= 0) {
          branch.useExpression(expr);
          if (r.isLocal(target, branch.end - 1)) {
            return Assignment(r.getTarget(target, branch.end - 1), branch.asExpression(r));
          }
          r.setValue(target, branch.end - 1, branch.asExpression(r));
        } else {
          print('-- fail ${branch.end - 1}');
          print(expr);
          print(target);
        }
        return null;
      });
    }
  }
}