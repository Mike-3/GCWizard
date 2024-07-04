import '../../parse/lfunction.dart';
import '../../util/stack.dart';
import '../branch/branch.dart';
import '../branch/testnode.dart';
import '../declaration.dart';
import '../decompiler.dart';
import '../expression/binaryexpression.dart';
import '../expression/expression.dart';
import '../expression/localvariable.dart';
import '../operation/operation.dart';
import '../output.dart';
import '../registers.dart';
import '../statement/assignment.dart';
import '../statement/statement.dart';
import 'block.dart';

class IfThenEndBlock extends Block {
  final Branch branch;
  final Stack<Branch>? stack;
  final Registers r;
  final List<Statement> statements;

  IfThenEndBlock(LFunction function, Branch branch, Registers r)
      : this.withParameters(function, branch, null, r);

  IfThenEndBlock.withParameters(LFunction function, Branch branch, this.stack, this.r)
      : branch = branch,
        statements = List<Statement>.filled(branch.end - branch.begin + 1, Statement()),
        super(function, branch.begin == branch.end ? branch.begin - 1 : branch.begin,
            branch.begin == branch.end ? branch.begin - 1 : branch.end);

  @override
  void addStatement(Statement statement) {
    statements.add(statement);
  }

  @override
  bool breakable() {
    return false;
  }

  @override
  bool isContainer() {
    return true;
  }

  @override
  bool isUnprotected() {
    return false;
  }

  @override
  int getLoopback() {
    throw StateError('Illegal state');
  }

  @override
  void print(Decompiler d, Output out) {
    out.print('if ');
    branch.asExpression(r).print(d, out);
    out.print(' then');
    out.println();
    out.indent();
    Statement.printSequence(d, out, statements);
    out.dedent();
    out.print('end');
  }

  @override
  Operation process(Decompiler d) {
    if (statements.length == 1) {
      Statement stmt = statements[0];
      if (stmt is Assignment) {
        final Assignment assign = stmt;
        if (assign.getArity() == 1) {
          if (branch is TestNode) {
            TestNode node = branch as TestNode;
            Declaration decl = r.getDeclaration(node.test, node.line);
            if (assign.getFirstTarget().isDeclaration(decl)) {
              final Expression expr;
              if (node.invert) {
                expr = BinaryExpression('or', LocalVariable(decl), assign.getFirstValue(),
                    Expression.PRECEDENCE_OR, Expression.ASSOCIATIVITY_NONE);
              } else {
                expr = BinaryExpression('and', LocalVariable(decl), assign.getFirstValue(),
                    Expression.PRECEDENCE_AND, Expression.ASSOCIATIVITY_NONE);
              }
              return Operation(end - 1, (Registers r, Block block) {
                return Assignment.withTargetValue(assign.getFirstTarget(), expr);
              });
            }
          }
        }
      }
    } else if (statements.isEmpty && stack != null) {
      int test = branch.getRegister();
      if (test < 0) {
        for (int reg = 0; reg < r.registers; reg++) {
          if (r.getUpdated(reg, branch.end - 1) >= branch.begin) {
            if (test >= 0) {
              test = -1;
              break;
            }
            test = reg;
          }
        }
      }
      if (test >= 0) {
        if (r.getUpdated(test, branch.end - 1) >= branch.begin) {
          Expression right = r.getValue(test, branch.end);
          final Branch setb = d.popSetCondition(stack!, stack!.peek().end, test);
          setb.useExpression(right);
          final int testreg = test;
          return Operation(end - 1, (Registers r, Block block) {
            r.setValue(testreg, branch.end - 1, setb.asExpression(r));
            return null;
          });
        }
      }
    }
    return super.process(d);
  }
}