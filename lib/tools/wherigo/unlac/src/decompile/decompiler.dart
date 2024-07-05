import 'dart:collection';
import 'dart:core';
import 'dart:math';

import '../configuration.dart';
import '../parse/lboolean.dart';
import '../parse/lfunction.dart';
import '../util/stack.dart';
import '../util/exception.dart';
import '../version.dart';
import 'block/alwaysloop.dart';
import 'block/block.dart';
import 'block/booleanindicator.dart';
import 'block/break.dart';
import 'block/compareblock.dart';
import 'block/doendblock.dart';
import 'block/elseendblock.dart';
import 'block/forblock.dart';
import 'block/ifthenelseblock.dart';
import 'block/ifthenendblock.dart';
import 'block/outerblock.dart';
import 'block/repeatblock.dart';
import 'block/setblock.dart';
import 'block/tforblock.dart';
import 'block/whileblock.dart';
import 'branch/andbranch.dart';
import 'branch/assignnode.dart';
import 'branch/branch.dart';
import 'branch/eqnode.dart';
import 'branch/lenode.dart';
import 'branch/ltnode.dart';
import 'branch/orbranch.dart';
import 'branch/testnode.dart';
import 'branch/testsetnode.dart';
import 'branch/truenode.dart';
import 'code.dart';
import 'declaration.dart';
import 'expression/closureexpression.dart';
import 'expression/constantexpression.dart';
import 'expression/expression.dart';
import 'expression/functioncall.dart';
import 'expression/tableliteral.dart';
import 'expression/tablereference.dart';
import 'expression/vararg.dart';
import 'function.dart';
import 'op.dart';
import 'operation/calloperation.dart';
import 'operation/globalset.dart';
import 'operation/operation.dart';
import 'operation/registerset.dart';
import 'operation/returnoperation.dart';
import 'operation/tableset.dart';
import 'operation/upvalueset.dart';
import 'output.dart';
import 'registers.dart';
import 'statement/assignment.dart';
import 'statement/statement.dart';
import 'target/globaltarget.dart';
import 'target/tabletarget.dart';
import 'target/target.dart';
import 'target/upvaluetarget.dart';
import 'target/variabletarget.dart';
import 'upvalues.dart';
import 'variablefinder.dart';

class Decompiler {
  final int registers;
  final int length;
  final Code code;
  final Upvalues upvalues;
  final List<Declaration> declList;

  late Function_ f;
  late LFunction function;
  final List<LFunction> functions;
  final int params;
  final int vararg;

  final Op tforTarget;
  final Op? forTarget;

  Decompiler(LFunction this.function, [List<Declaration>? parentDecls, int line = -1])
      : f = Function_(function),
        function = function,
        registers = function.maximumStackSize,
        length = function.code.length,
        code = Code(function),
        declList = function.stripped
            ? VariableFinder.process(this, function.numParams, function.maximumStackSize)
            : function.locals.length >= function.numParams
                ? List.generate(function.locals.length, (i) => Declaration(function.locals[i]))
                : List.generate(function.numParams, (i) => Declaration.withParams("_ARG_$i" + "_", 0, length - 1)),
        upvalues = Upvalues(function, parentDecls, line),
        functions = function.functions,
        params = function.numParams,
        vararg = function.vararg,
        tforTarget = function.header.version.getTForTarget(),
        forTarget = function.header.version.getForTarget();
  
  Configuration getConfiguration() {
    return function.header.config;
  }
  
  Version getVersion() {
    return function.header.version;
  }

  late Registers r;
  late Block outer;
  
  void decompile() {
    r = Registers(registers, length, declList, f);
    findReverseTargets();
    handleBranches(true);
    outer = handleBranches(false);
    processSequence(1, length);
  }

  void print_() {
    print(Output());
  }

  void print__(OutputProvider out) {
    print(Output.withProvider(out));
  }
  
  void print(Output out) {
    handleInitialDeclares(out);
    outer.print(this, out);
  }
  
  void handleInitialDeclares(Output out) {
    List<Declaration> initdecls = [];
    for (int i = params + (vararg & 1); i < declList.length; i++) {
      if (declList[i].begin == 0) {
        initdecls.add(declList[i]);
      }
    }
    if (initdecls.isNotEmpty) {
      out.print("local ");
      out.print(initdecls[0].name);
      for (int i = 1; i < initdecls.length; i++) {
        out.print(", ");
        out.print(initdecls[i].name);
      }
      out.println();
    }
  }
  
  int fb2int50(int fb) {
    return (fb & 7) << (fb >> 3);
  }
  
  int fb2int(int fb) {
    int exponent = (fb >> 3) & 0x1f;
    if (exponent == 0) {
      return fb;
    } else {
      return ((fb & 7) + 8) << (exponent - 1);
    }
  }
  
  var skip = <bool>[];

  var reverseTarget = <bool>[];
  
  void findReverseTargets() {
    reverseTarget = List.filled(length + 1, false);
    for (int line = 1; line <= length; line++) {
      if (code.op(line) == Op.JMP && code.sBx(line) < 0) {
        reverseTarget[line + 1 + code.sBx(line)] = true;
      }
    }
  }
  
  Assignment? processOperation(Operation operation, int line, int nextLine, Block block) {
    Assignment? assign;
    bool wasMultiple = false;
    Statement? stmt = operation.process(r, block);
    if (stmt != null) {
      if (stmt is Assignment) {
        assign = stmt;
        if (!assign.getFirstValue()!.isMultiple()) {
          block.addStatement(stmt);
        } else {
          wasMultiple = true;
        }
      } else {
        block.addStatement(stmt);
      }
      if (assign != null) {
        while (nextLine < block.end && isMoveIntoTarget(nextLine)) {
          Target target = getMoveIntoTargetTarget(nextLine, line + 1);
          Expression value = getMoveIntoTargetValue(nextLine, line + 1);
          assign.addFirst(target, value);
          skip[nextLine] = true;
          nextLine++;
        }
        if (wasMultiple && !assign.getFirstValue()!.isMultiple()) {
          block.addStatement(stmt);
        }
      }
    }
    return assign;
  }
  
  bool isMoveIntoTarget(int line) {
    switch (code.op(line)) {
      case Op.MOVE:
        return r.isAssignable(code.A(line), line) && !r.isLocal(code.B(line), line);
      case Op.SETUPVAL:
      case Op.SETGLOBAL:
        return !r.isLocal(code.A(line), line);
      case Op.SETTABLE:
      case Op.SETTABUP:
        int C = code.C(line);
        if (f.isConstant(C)) {
          return false;
        } else {
          return !r.isLocal(C, line);
        }
      default:
        return false;
    }
  }
  
  Target getMoveIntoTargetTarget(int line, int previous) {
    switch (code.op(line)) {
      case Op.MOVE:
        return r.getTarget(code.A(line), line);
      case Op.SETUPVAL:
        return UpvalueTarget(upvalues.getName(code.B(line)));
      case Op.SETGLOBAL:
        return GlobalTarget(f.getGlobalName(code.Bx(line)));
      case Op.SETTABLE:
        return TableTarget(r.getExpression(code.A(line), previous), r.getKExpression(code.B(line), previous));
      case Op.SETTABUP:
        int A = code.A(line);
        int B = code.B(line);
        return TableTarget(upvalues.getExpression(A), r.getKExpression(B, previous));
      default:
        throw StateError(code.op(line).toString());
    }
  }
  
  Expression getMoveIntoTargetValue(int line, int previous) {
    int A = code.A(line);
    int B = code.B(line);
    int C = code.C(line);
    switch (code.op(line)) {
      case Op.MOVE:
        return r.getValue(B, previous);
      case Op.SETUPVAL:
      case Op.SETGLOBAL:
        return r.getExpression(A, previous);
      case Op.SETTABLE:
      case Op.SETTABUP:
        if (f.isConstant(C)) {
          throw StateError(code.op(line).toString());
        } else {
          return r.getExpression(C, previous);
        }
      default:
        throw StateError(code.op(line).toString());
    }
  }
  
  var blocks = <Block>[];
  
  int breakTarget(int line) {
    int tline = double.infinity.toInt();
    for (Block block in blocks) {
      if (block.breakable() && block.contains(line)) {
        tline = tline < block.end ? tline : block.end;
      }
    }
    return tline == double.infinity ? -1 : tline;
  }
  
  Block enclosingBlock(int line) {
    Block outer = blocks[0];
    Block enclosing = outer;
    for (int i = 1; i < blocks.length; i++) {
      Block next = blocks[i];
      if (next.isContainer() && enclosing.contains(next) && next.contains(line) && !next.loopRedirectAdjustment) {
        enclosing = next;
      }
    }
    return enclosing;
  }
  
  Block enclosingBlock_(Block block) {
    Block outer = blocks[0];
    Block enclosing = outer;
    for (int i = 1; i < blocks.length; i++) {
      Block next = blocks[i];
      if (next == block) continue;
      if (next.contains(block) && enclosing.contains(next)) {
        enclosing = next;
      }
    }
    return enclosing;
  }
  
  Block? enclosingBreakableBlock(int line) {
    Block outer = blocks[0];
    Block enclosing = outer;
    for (int i = 1; i < blocks.length; i++) {
      Block next = blocks[i];
      if (enclosing.contains(next) && next.contains(line) && next.breakable() && !next.loopRedirectAdjustment) {
        enclosing = next;
      }
    }
    return enclosing == outer ? null : enclosing;
  }
  
  Block? enclosingUnprotectedBlock(int line) {
    Block outer = blocks[0];
    Block enclosing = outer;
    for (int i = 1; i < blocks.length; i++) {
      Block next = blocks[i];
      if (enclosing.contains(next) && next.contains(line) && next.isUnprotected() && !next.loopRedirectAdjustment) {
        enclosing = next;
      }
    }
    return enclosing == outer ? null : enclosing;
  }
  
  Stack<Branch>? backup;
  
  Branch popCondition(Stack<Branch> stack) {
    Branch branch = stack.pop();
    if (backup != null) backup.push(branch);
    if (branch is TestSetNode) {
      throw StateError();
    }
    int begin = branch.begin;
    if (code.op(branch.begin) == Op.JMP) {
      begin += 1 + code.sBx(branch.begin);
    }
    while (!stack.isEmpty) {
      Branch next = stack.peek;
      if (next is TestSetNode) break;
      if (next.end == begin) {
        branch = OrBranch(popCondition(stack).invert(), branch);
      } else if (next.end == branch.end) {
        branch = AndBranch(popCondition(stack), branch);
      } else {
        break;
      }
    }
    return branch;
  }
  
  Branch popSetCondition(Stack<Branch> stack, int assignEnd, int target) {
    stack.push(AssignNode(assignEnd - 1, assignEnd, assignEnd));
    Branch rtn = _helper_popSetCondition(stack, false, assignEnd, target);
    return rtn;
  }
  
  Branch popCompareSetCondition(Stack<Branch> stack, int assignEnd, int target) {
    Branch top = stack.pop();
    bool invert = code.B(top.begin) == 0;
    top.begin = assignEnd;
    top.end = assignEnd;
    stack.push(top);
    Branch rtn = _helper_popSetCondition(stack, invert, assignEnd, target);
    return rtn;
  }
  
  int _adjustLine(int line, int target) {
    int testline = line;
    while (testline >= 1 && code.op(testline) == Op.LOADBOOL && (target == -1 || code.A(testline) == target)) {
      testline--;
    }
    if (testline == line) {
      return testline;
    }
    testline++;
    if (code.C(testline) != 0) {
      return testline + 2;
    } else {
      return testline + 1;
    }
  }
  
  Branch _helper_popSetCondition(Stack<Branch> stack, bool invert, int assignEnd, int target) {
    Branch branch = stack.pop();
    int begin = branch.begin;
    int end = branch.end;
    if (invert) {
      branch = branch.invert();
    }
    begin = _adjustLine(begin, target);
    end = _adjustLine(end, target);
    int btarget = branch.setTarget;
    while (!stack.isEmpty) {
      Branch next = stack.peek;
      bool ninvert;
      int nend = next.end;
      if (code.op(nend) == Op.LOADBOOL && (target == -1 || code.A(nend) == target)) {
        ninvert = code.B(nend) != 0;
        nend = _adjustLine(nend, target);
      } else if (next is TestSetNode) {
        TestSetNode node = next;
        ninvert = node.invert;
      } else if (next is TestNode) {
        TestNode node = next;
        ninvert = node.invert;
      } else {
        ninvert = false;
        if (nend >= assignEnd) {
          break;
        }
      }
      int addr;
      if (ninvert == invert) {
        addr = end;
      } else {
        addr = begin;
      }
      
      if (addr == nend) {
        if (addr != nend) ninvert = !ninvert;
        if (ninvert) {
          branch = OrBranch(_helper_popSetCondition(stack, ninvert, assignEnd, target), branch);
        } else {
          branch = AndBranch(_helper_popSetCondition(stack, ninvert, assignEnd, target), branch);
        }
        branch.end = nend;
      } else {
        if ((branch is! TestSetNode)) {
          stack.push(branch);
          branch = popCondition(stack);
        }
        break;
      }
    }
    branch.isSet = true;
    branch.setTarget = btarget;
    return branch;
  }

  bool isStatement(int line, [int testRegister = -1]) {
    switch (code.op(line)) {
      case Op.MOVE:
      case Op.LOADK:
      case Op.LOADBOOL:
      case Op.GETUPVAL:
      case Op.GETTABUP:
      case Op.GETGLOBAL:
      case Op.GETTABLE:
      case Op.NEWTABLE:
      case Op.NEWTABLE50:
      case Op.ADD:
      case Op.SUB:
      case Op.MUL:
      case Op.DIV:
      case Op.MOD:
      case Op.POW:
      case Op.UNM:
      case Op.NOT:
      case Op.LEN:
      case Op.IDIV:
      case Op.BAND:
      case Op.BOR:
      case Op.BXOR:
      case Op.SHL:
      case Op.SHR:
      case Op.BNOT:
      case Op.CONCAT:
      case Op.CLOSURE:
        return r.isLocal(code.A(line), line) || code.A(line) == testRegister;
      case Op.LOADNIL:
        for (int register = code.A(line); register <= code.B(line); register++) {
          if (r.isLocal(register, line)) {
            return true;
          }
        }
        return false;
      case Op.SETGLOBAL:
      case Op.SETUPVAL:
      case Op.SETTABUP:
      case Op.SETTABLE:
      case Op.JMP:
      case Op.TAILCALL:
      case Op.RETURN:
      case Op.FORLOOP:
      case Op.FORPREP:
      case Op.TFORPREP:
      case Op.TFORCALL:
      case Op.TFORLOOP:
      case Op.CLOSE:
        return true;
      case Op.SELF:
        return r.isLocal(code.A(line), line) || r.isLocal(code.A(line) + 1, line);
      case Op.EQ:
      case Op.LT:
      case Op.LE:
      case Op.TEST:
      case Op.TESTSET:
      case Op.TEST50:
      case Op.SETLIST:
      case Op.SETLISTO:
      case Op.SETLIST50:
        return false;
      case Op.CALL: {
        int a = code.A(line);
        int c = code.C(line);
        if (c == 1) {
          return true;
        }
        if (c == 0) c = registers - a + 1;
        for (int register = a; register < a + c - 1; register++) {
          if (r.isLocal(register, line)) {
            return true;
          }
        }
        return (c == 2 && a == testRegister);
      }
      case Op.VARARG: {
        int a = code.A(line);
        int b = code.B(line);
        if (b == 0) b = registers - a + 1;
        for (int register = a; register < a + b - 1; register++) {
          if (r.isLocal(register, line)) {
            return true;
          }
        }
        return false;
      }
      default:
        throw StateError("Illegal opcode: ${code.op(line)}");
    }
  }
  
  int getAssignment(int line) {
    switch (code.op(line)) {
      case Op.MOVE:
      case Op.LOADK:
      case Op.LOADBOOL:
      case Op.GETUPVAL:
      case Op.GETTABUP:
      case Op.GETGLOBAL:
      case Op.GETTABLE:
      case Op.NEWTABLE:
      case Op.NEWTABLE50:
      case Op.ADD:
      case Op.SUB:
      case Op.MUL:
      case Op.DIV:
      case Op.MOD:
      case Op.POW:
      case Op.UNM:
      case Op.NOT:
      case Op.LEN:
      case Op.IDIV:
      case Op.BAND:
      case Op.BOR:
      case Op.BXOR:
      case Op.SHL:
      case Op.SHR:
      case Op.BNOT:
      case Op.CONCAT:
      case Op.CLOSURE:
        return code.A(line);
      case Op.LOADNIL:
        return code.A(line) == code.B(line) ? code.A(line) : -1;
      case Op.SETGLOBAL:
      case Op.SETUPVAL:
      case Op.SETTABUP:
      case Op.SETTABLE:
      case Op.JMP:
      case Op.TAILCALL:
      case Op.RETURN:
      case Op.FORLOOP:
      case Op.FORPREP:
      case Op.TFORCALL:
      case Op.TFORLOOP:
      case Op.CLOSE:
        return -1;
      case Op.SELF:
        return -1;
      case Op.EQ:
      case Op.LT:
      case Op.LE:
      case Op.TEST:
      case Op.TESTSET:
      case Op.SETLIST:
      case Op.SETLIST50:
      case Op.SETLISTO:
        return -1;
      case Op.CALL: {
        if (code.C(line) == 2) {
          return code.A(line);
        } else {
          return -1;
        }
      }
      case Op.VARARG: {
        if (code.C(line) == 2) {
          return code.B(line);
        } else {
          return -1;
        }
      }
      default:
        throw StateError("Illegal opcode: ${code.op(line)}");
    }
  }

  OuterBlock handleBranches(bool first) {
    List<Block> oldBlocks = blocks;
    blocks = [];
    OuterBlock outer = OuterBlock(function, length);
    blocks.add(outer);
    var isBreak = List<bool>.filled(length + 1, false);
    var loopRemoved = List<bool>.filled(length + 1, false);
    if (!first) {
      for (Block block in oldBlocks) {
        if (block is AlwaysLoop) {
          blocks.add(block);
        }
        if (block is Break) {
          blocks.add(block);
          isBreak[block.begin] = true;
        }
      }
      List<Block> delete = [];
      for (Block block in blocks) {
        if (block is AlwaysLoop) {
          for (Block block2 in blocks) {
            if (block != block2) {
              if (block.begin == block2.begin) {
                if (block.end < block2.end) {
                  delete.add(block);
                  loopRemoved[block.end - 1] = true;
                } else {
                  delete.add(block2);
                  loopRemoved[block2.end - 1] = true;
                }
              }
            }
          }
        }
      }
      for (Block block in delete) {
        blocks.remove(block);
      }
    }
    skip = List<bool>.filled(length + 1, false);
    Stack<Branch> stack = Stack<Branch>();
    bool reduce = false;
    bool testset = false;
    int testsetend = -1;
    for (int line = 1; line <= length; line++) {
      if (!skip[line]) {
        switch (code.op(line)) {
          case Op.EQ:
            {
              EQNode node = EQNode(code.B(line), code.C(line), code.A(line) != 0, line, line + 2, line + 2 + code.sBx(line + 1));
              stack.push(node);
              skip[line + 1] = true;
              if (code.op(node.end) == Op.LOADBOOL) {
                if (code.C(node.end) != 0) {
                  node.isCompareSet = true;
                  node.setTarget = code.A(node.end);
                } else if (node.end - 1 >= 1 && code.op(node.end - 1) == Op.LOADBOOL) {
                  if (code.C(node.end - 1) != 0) {
                    node.isCompareSet = true;
                    node.setTarget = code.A(node.end);
                  }
                }
              }
              continue;
            }
          case Op.LT:
            {
              LTNode node = LTNode(code.B(line), code.C(line), code.A(line) != 0, line, line + 2, line + 2 + code.sBx(line + 1));
              stack.push(node);
              skip[line + 1] = true;
              if (code.op(node.end) == Op.LOADBOOL) {
                if (code.C(node.end) != 0) {
                  node.isCompareSet = true;
                  node.setTarget = code.A(node.end);
                } else if (node.end - 1 >= 1 && code.op(node.end - 1) == Op.LOADBOOL) {
                  if (code.C(node.end - 1) != 0) {
                    node.isCompareSet = true;
                    node.setTarget = code.A(node.end);
                  }
                }
              }
              continue;
            }
          case Op.LE:
            {
              LENode node = LENode(code.B(line), code.C(line), code.A(line) != 0, line, line + 2, line + 2 + code.sBx(line + 1));
              stack.push(node);
              skip[line + 1] = true;
              if (code.op(node.end) == Op.LOADBOOL) {
                if (code.C(node.end) != 0) {
                  node.isCompareSet = true;
                  node.setTarget = code.A(node.end);
                } else if (node.end - 1 >= 1 && code.op(node.end - 1) == Op.LOADBOOL) {
                  if (code.C(node.end - 1) != 0) {
                    node.isCompareSet = true;
                    node.setTarget = code.A(node.end);
                  }
                }
              }
              continue;
            }
          case Op.TEST:
            stack.push(TestNode(code.A(line), code.C(line) != 0, line, line + 2, line + 2 + code.sBx(line + 1)));
            skip[line + 1] = true;
            continue;
          case Op.TESTSET:
            testset = true;
            testsetend = line + 2 + code.sBx(line + 1);
            stack.push(TestSetNode(code.A(line), code.B(line), code.C(line) != 0, line, line + 2, line + 2 + code.sBx(line + 1)));
            skip[line + 1] = true;
            continue;
          case Op.TEST50:
            if (code.A(line) == code.B(line)) {
              stack.push(TestNode(code.A(line), code.C(line) != 0, line, line + 2, line + 2 + code.sBx(line + 1)));
            } else {
              testset = true;
              testsetend = line + 2 + code.sBx(line + 1);
              stack.push(TestSetNode(code.A(line), code.B(line), code.C(line) != 0, line, line + 2, line + 2 + code.sBx(line + 1)));
            }
            skip[line + 1] = true;
            continue;
          case Op.JMP:
            {
              reduce = true;
              int tline = line + 1 + code.sBx(line);
              if (tline >= 2 && code.op(tline - 1) == Op.LOADBOOL && code.C(tline - 1) != 0) {
                stack.push(TrueNode(code.A(tline - 1), false, line, line + 1, tline));
                skip[line + 1] = true;
              } else if (code.op(tline) == tforTarget && !skip[tline]) {
                int A = code.A(tline);
                int C = code.C(tline);
                if (C == 0) throw IllegalStateException();
                r.setInternalLoopVariable(A, tline, line + 1);
                r.setInternalLoopVariable(A + 1, tline, line + 1);
                r.setInternalLoopVariable(A + 2, tline, line + 1);
                for (int index = 1; index <= C; index++) {
                  r.setExplicitLoopVariable(A + 2 + index, line, tline + 2);
                }
                skip[tline] = true;
                skip[tline + 1] = true;
                blocks.add(TForBlock(function, line + 1, tline + 2, A, C, r));
              } else if (code.op(tline) == forTarget && !skip[tline]) {
                int A = code.A(tline);
                r.setInternalLoopVariable(A, tline, line + 1);
                r.setInternalLoopVariable(A + 1, tline, line + 1);
                r.setInternalLoopVariable(A + 2, tline, line + 1);
                skip[tline] = true;
                blocks.add(ForBlock(function, line + 1, tline + 1, A, r));
              } else if (code.sBx(line) == 2 && code.op(line + 1) == Op.LOADBOOL && code.C(line + 1) != 0) {
                blocks.add(BooleanIndicator(function, line));
              } else if (code.op(tline) == Op.JMP && code.sBx(tline) + tline == line) {
                if (first) blocks.add(AlwaysLoop(function, line, tline + 1));
                skip[tline] = true;
              } else {
                if (first || loopRemoved[line] || reverseTarget[line + 1]) {
                  if (!isBreak[line]) {
                    if (tline > line) {
                      isBreak[line] = true;
                      blocks.add(Break(function, line, tline));
                    } else {
                      Block enclosing = enclosingBreakableBlock(line);
                      if (enclosing != null && enclosing.breakable() && code.op(enclosing.end) == Op.JMP && code.sBx(enclosing.end) + enclosing.end + 1 == tline) {
                        isBreak[line] = true;
                        blocks.add(Break(function, line, enclosing.end));
                      } else {
                        blocks.add(AlwaysLoop(function, tline, line + 1));
                      }
                    }
                  }
                }
              }
              break;
            }
          case Op.FORPREP:
            reduce = true;
            blocks.add(ForBlock(function, line + 1, line + 2 + code.sBx(line), code.A(line), r));
            skip[line + 1 + code.sBx(line)] = true;
            r.setInternalLoopVariable(code.A(line), line, line + 2 + code.sBx(line));
            r.setInternalLoopVariable(code.A(line) + 1, line, line + 2 + code.sBx(line));
            r.setInternalLoopVariable(code.A(line) + 2, line, line + 2 + code.sBx(line));
            r.setExplicitLoopVariable(code.A(line) + 3, line, line + 2 + code.sBx(line));
            break;
          case Op.FORLOOP:
            throw IllegalStateException();
          case Op.TFORPREP:
            {
              reduce = true;
              int tline = line + 1 + code.sBx(line);
              int A = code.A(tline);
              int C = code.C(tline);
              r.setInternalLoopVariable(A, tline, line + 1);
              r.setInternalLoopVariable(A + 1, tline, line + 1);
              r.setInternalLoopVariable(A + 2, tline, line + 1);
              for (int index = 1; index <= C; index++) {
                r.setExplicitLoopVariable(A + 2 + index, line, tline + 2);
              }
              skip[tline] = true;
              skip[tline + 1] = true;
              blocks.add(TForBlock(function, line + 1, tline + 2, A, C, r));
              break;
            }
          default:
            reduce = isStatement(line);
            break;
        }
      }

      if ((line + 1) <= length && reverseTarget[line + 1]) {
        reduce = true;
      }
      if (testset && testsetend == line + 1) {
        reduce = true;
      }
      if (stack.isEmpty) {
        reduce = false;
      }
      if (reduce) {
        reduce = false;
        Stack<Branch> conditions = Stack<Branch>();
        Stack<Stack<Branch>> backups = Stack<Stack<Branch>>();
        do {
          bool isAssignNode = stack.peek is TestSetNode;
          int assignEnd = stack.peek.end;
          bool compareCorrect = false;
          if (stack.peek is TrueNode) {
            isAssignNode = true;
            compareCorrect = true;
            if (code.C(assignEnd) != 0) {
              assignEnd += 2;
            } else {
              assignEnd += 1;
            }
          } else if (stack.peek.isCompareSet) {
            if (code.op(stack.peek.begin) != Op.LOADBOOL || code.C(stack.peek.begin) == 0) {
              isAssignNode = true;
              if (code.C(assignEnd) != 0) {
                assignEnd += 2;
              } else {
                assignEnd += 1;
              }
              compareCorrect = true;
            }
          } else if (assignEnd - 3 >= 1 && code.op(assignEnd - 2) == Op.LOADBOOL && code.C(assignEnd - 2) != 0 && code.op(assignEnd - 3) == Op.JMP && code.sBx(assignEnd - 3) == 2) {
            if (stack.peek is TestNode) {
              TestNode node = stack.peek;
              if (node.test == code.A(assignEnd - 2)) {
                isAssignNode = true;
              }
            }
          } else if (assignEnd - 2 >= 1 && code.op(assignEnd - 1) == Op.LOADBOOL && code.C(assignEnd - 1) != 0 && code.op(assignEnd - 2) == Op.JMP && code.sBx(assignEnd - 2) == 2) {
            if (stack.peek is TestNode) {
              isAssignNode = true;
              assignEnd += 1;
            }
          } else if (assignEnd - 1 >= 1 && code.op(assignEnd) == Op.LOADBOOL && code.C(assignEnd) != 0 && code.op(assignEnd - 1) == Op.JMP && code.sBx(assignEnd - 1) == 2) {
            if (stack.peek is TestNode) {
              isAssignNode = true;
              assignEnd += 2;
            }
          } else if (assignEnd - 1 >= 1 && r.isLocal(getAssignment(assignEnd - 1), assignEnd - 1) && assignEnd > stack.peek.line) {
            Declaration decl = r.getDeclaration(getAssignment(assignEnd - 1), assignEnd - 1);
            if (decl.begin == assignEnd - 1 && decl.end > assignEnd - 1) {
              isAssignNode = true;
            }
          }
          if (!compareCorrect && assignEnd - 1 == stack.peek.begin && code.op(stack.peek.begin) == Op.LOADBOOL && code.C(stack.peek.begin) != 0) {
            backup = null;
            int begin = stack.peek.begin;
            assignEnd = begin + 2;
            int target = code.A(begin);
            conditions.push(popCompareSetCondition(stack, assignEnd, target));
            conditions.peek.setTarget = target;
            conditions.peek.end = assignEnd;
            conditions.peek.begin = begin;
          } else if (isAssignNode) {
            backup = null;
            int target = stack.peek.setTarget;
            int begin = stack.peek.begin;
            conditions.push(popSetCondition(stack, assignEnd, target));
            conditions.peek.setTarget = target;
            conditions.peek.end = assignEnd;
            conditions.peek.begin = begin;
          } else {
            backup = Stack<Branch>();
            conditions.push(popCondition(stack));
            backup.reverse();
          }
          backups.push(backup);
        } while (!stack.isEmpty);
        do {
          Branch cond = conditions.pop();
          Stack<Branch> backup = backups.pop();
          int breakTarget_ = breakTarget(cond.begin);
          bool breakable = (breakTarget_ >= 1);
          if (breakable && code.op(breakTarget_) == Op.JMP && breakTarget_ != cond.end) {
            breakTarget_ += 1 + code.sBx(breakTarget_);
          }
          if (breakable && breakTarget_ == cond.end) {
            Block immediateEnclosing = enclosingBlock(cond.begin);
            Block? breakableEnclosing = enclosingBreakableBlock(cond.begin);
            int loopstart = immediateEnclosing.end;
            if (immediateEnclosing == breakableEnclosing) loopstart--;
            for (int iline = loopstart; iline >= max(cond.begin, immediateEnclosing.begin); iline--) {
              if (code.op(iline) == Op.JMP && iline + 1 + code.sBx(iline) == breakTarget_) {
                cond.end = iline;
                break;
              }
            }
          }
          bool hasTail = cond.end >= 2 && code.op(cond.end - 1) == Op.JMP;
          int tail = hasTail ? cond.end + code.sBx(cond.end - 1) : -1;
          int originalTail = tail;
          Block? enclosing = enclosingUnprotectedBlock(cond.begin);
          if (enclosing != null) {
            if (enclosing.getLoopback() == cond.end) {
              cond.end = enclosing.end - 1;
              hasTail = cond.end >= 2 && code.op(cond.end - 1) == Op.JMP;
              tail = hasTail ? cond.end + code.sBx(cond.end - 1) : -1;
            }
            if (hasTail && enclosing.getLoopback() == tail) {
              tail = enclosing.end - 1;
            }
          }
          if (cond.isSet) {
            bool empty = cond.begin == cond.end;
            if (code.op(cond.begin) == Op.JMP && code.sBx(cond.begin) == 2 && code.op(cond.begin + 1) == Op.LOADBOOL && code.C(cond.begin + 1) != 0) {
              empty = true;
            }
            blocks.add(SetBlock(function, cond, cond.setTarget, line, cond.begin, cond.end, empty, r));
          } else if (code.op(cond.begin) == Op.LOADBOOL && code.C(cond.begin) != 0) {
            int begin = cond.begin;
            int target = code.A(begin);
            if (code.B(begin) == 0) {
              cond = cond.invert();
            }
            blocks.add(CompareBlock(function, begin, begin + 2, target, cond));
          } else if (cond.end < cond.begin) {
            if (isBreak[cond.end - 1]) {
              skip[cond.end - 1] = true;
              blocks.add(WhileBlock(function, cond.invert(), originalTail, r));
            } else {
              blocks.add(RepeatBlock(function, cond, r));
            }
          } else if (hasTail) {
            Op endOp = code.op(cond.end - 2);
            bool isEndCondJump = endOp == Op.EQ || endOp == Op.LE || endOp == Op.LT || endOp == Op.TEST || endOp == Op.TESTSET || endOp == Op.TEST50;
            if (tail > cond.end || (tail == cond.end && !isEndCondJump)) {
              Op op = code.op(tail - 1);
              int sbx = code.sBx(tail - 1);
              int loopback2 = tail + sbx;
              bool isBreakableLoopEnd = function.header.version.isBreakableLoopEnd(op);
              if (isBreakableLoopEnd && loopback2 <= cond.begin && !isBreak[tail - 1]) {
                blocks.add(IfThenEndBlock.withParameters(function, cond, backup, r));
              } else {
                skip[cond.end - 1] = true;
                bool emptyElse = tail == cond.end;
                IfThenElseBlock ifthen = IfThenElseBlock(function, cond, originalTail, emptyElse, r);
                blocks.add(ifthen);

                if (!emptyElse) {
                  ElseEndBlock elseend = ElseEndBlock(function, cond.end, tail);
                  blocks.add(elseend);
                }
              }
            } else {
              int loopback = tail;
              bool existsStatement = false;
              for (int sl = loopback; sl < cond.begin; sl++) {
                if (!skip[sl] && isStatement(sl)) {
                  existsStatement = true;
                  break;
                }
              }
              if (loopback >= cond.begin || existsStatement) {
                blocks.add(IfThenEndBlock.withParameters(function, cond, backup, r));
              } else {
                skip[cond.end - 1] = true;
                blocks.add(WhileBlock(function, cond, originalTail, r));
              }
            }
          } else {
            blocks.add(IfThenEndBlock.withParameters(function, cond, backup, r));
          }
        } while (!conditions.isEmpty());
      }
    }
    for (Declaration decl in declList) {
      if (!decl.forLoop && !decl.forLoopExplicit) {
        bool needsDoEnd = true;
        for (Block block in blocks) {
          if (block.contains(decl.begin)) {
            if (block.scopeEnd() == decl.end) {
              needsDoEnd = false;
              break;
            }
          }
        }
        if (needsDoEnd) {
          blocks.add(DoEndBlock(function, decl.begin, decl.end + 1));
        }
      }
    }
    ListIterator<Block> iter = blocks.listIterator();
    while (iter.hasNext()) {
      Block block = iter.next();
      if (skip[block.begin] && block is Break) {
        iter.remove();
      }
    }
    Collections.sort(blocks);
    backup = null;
    return outer;
  }
  
    List<Operation> processLine(int line) {
    List<Operation> operations = LinkedList<Operation>();
    int A = code.A(line);
    int B = code.B(line);
    int C = code.C(line);
    int Bx = code.Bx(line);
    switch (code.op(line)) {
      case Op.MOVE:
        operations.add(RegisterSet(line, A, r.getExpression(B, line)));
        break;
      case Op.LOADK:
        operations.add(RegisterSet(line, A, f.getConstantExpression(Bx)));
        break;
      case Op.LOADBOOL:
        operations.add(RegisterSet(line, A, ConstantExpression(Constant(B != 0 ? LBoolean.LTRUE : LBoolean.LFALSE), -1)));
        break;
      case Op.LOADNIL:
        {
          int maximum;
          if (function.header.version.usesOldLoadNilEncoding()) {
            maximum = B;
          } else {
            maximum = A + B;
          }
          while (A <= maximum) {
            operations.add(RegisterSet(line, A, Expression.NIL));
            A++;
          }
          break;
        }
      case Op.GETUPVAL:
        operations.add(RegisterSet(line, A, upvalues.getExpression(B)));
        break;
      case Op.GETTABUP:
        operations.add(RegisterSet(line, A, TableReference(upvalues.getExpression(B), r.getKExpression(C, line))));
        break;
      case Op.GETGLOBAL:
        operations.add(RegisterSet(line, A, f.getGlobalExpression(Bx)));
        break;
      case Op.GETTABLE:
        operations.add(RegisterSet(line, A, TableReference(r.getExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.SETUPVAL:
        operations.add(UpvalueSet(line, upvalues.getName(B), r.getExpression(A, line)));
        break;
      case Op.SETTABUP:
        operations.add(TableSet(line, upvalues.getExpression(A), r.getKExpression(B, line), r.getKExpression(C, line), true, line));
        break;
      case Op.SETGLOBAL:
        operations.add(GlobalSet(line, f.getGlobalName(Bx), r.getExpression(A, line)));
        break;
      case Op.SETTABLE:
        operations.add(TableSet(line, r.getExpression(A, line), r.getKExpression(B, line), r.getKExpression(C, line), true, line));
        break;
      case Op.NEWTABLE:
        operations.add(RegisterSet(line, A, TableLiteral(fb2int(B), fb2int(C))));
        break;
      case Op.NEWTABLE50:
        operations.add(RegisterSet(line, A, TableLiteral(fb2int50(B), 1 << C)));
        break;
      case Op.SELF:
        {
          Expression common = r.getExpression(B, line);
          operations.add(RegisterSet(line, A + 1, common));
          operations.add(RegisterSet(line, A, TableReference(common, r.getKExpression(C, line))));
          break;
        }
      case Op.ADD:
        operations.add(RegisterSet(line, A, Expression.makeADD(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.SUB:
        operations.add(RegisterSet(line, A, Expression.makeSUB(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.MUL:
        operations.add(RegisterSet(line, A, Expression.makeMUL(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.DIV:
        operations.add(RegisterSet(line, A, Expression.makeDIV(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.MOD:
        operations.add(RegisterSet(line, A, Expression.makeMOD(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.POW:
        operations.add(RegisterSet(line, A, Expression.makePOW(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.IDIV:
        operations.add(RegisterSet(line, A, Expression.makeIDIV(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.BAND:
        operations.add(RegisterSet(line, A, Expression.makeBAND(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.BOR:
        operations.add(RegisterSet(line, A, Expression.makeBOR(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.BXOR:
        operations.add(RegisterSet(line, A, Expression.makeBXOR(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.SHL:
        operations.add(RegisterSet(line, A, Expression.makeSHL(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.SHR:
        operations.add(RegisterSet(line, A, Expression.makeSHR(r.getKExpression(B, line), r.getKExpression(C, line))));
        break;
      case Op.UNM:
        operations.add(RegisterSet(line, A, Expression.makeUNM(r.getExpression(B, line))));
        break;
      case Op.NOT:
        operations.add(RegisterSet(line, A, Expression.makeNOT(r.getExpression(B, line))));
        break;
      case Op.LEN:
        operations.add(RegisterSet(line, A, Expression.makeLEN(r.getExpression(B, line))));
        break;
      case Op.BNOT:
        operations.add(RegisterSet(line, A, Expression.makeBNOT(r.getExpression(B, line))));
        break;
      case Op.CONCAT:
        {
          Expression value = r.getExpression(C, line);
          while (C-- > B) {
            value = Expression.makeCONCAT(r.getExpression(C, line), value);
          }
          operations.add(RegisterSet(line, A, value));
          break;
        }
      case Op.JMP:
      case Op.EQ:
      case Op.LT:
      case Op.LE:
      case Op.TEST:
      case Op.TESTSET:
      case Op.TEST50:
        /* Do nothing ... handled with branches */
        break;
      case Op.CALL:
        {
          bool multiple = (C >= 3 || C == 0);
          if (B == 0) B = registers - A;
          if (C == 0) C = registers - A + 1;
          Expression function = r.getExpression(A, line);
          List<Expression> arguments = List<Expression>(B - 1);
          for (int register = A + 1; register <= A + B - 1; register++) {
            arguments[register - A - 1] = r.getExpression(register, line);
          }
          FunctionCall value = FunctionCall(function, arguments, multiple);
          if (C == 1) {
            operations.add(CallOperation(line, value));
          } else {
            if (C == 2 && !multiple) {
              operations.add(RegisterSet(line, A, value));
            } else {
              for (int register = A; register <= A + C - 2; register++) {
                operations.add(RegisterSet(line, register, value));
              }
            }
          }
          break;
        }
      case Op.TAILCALL:
        {
          if (B == 0) B = registers - A;
          Expression function = r.getExpression(A, line);
          List<Expression> arguments = List<Expression>(B - 1);
          for (int register = A + 1; register <= A + B - 1; register++) {
            arguments[register - A - 1] = r.getExpression(register, line);
          }
          FunctionCall value = FunctionCall(function, arguments, true);
          operations.add(ReturnOperation(line, value));
          skip[line + 1] = true;
          break;
        }
      case Op.RETURN:
        {
          if (B == 0) B = registers - A + 1;
          List<Expression> values = List<Expression>(B - 1);
          for (int register = A; register <= A + B - 2; register++) {
            values[register - A] = r.getExpression(register, line);
          }
          operations.add(ReturnOperation(line, values));
          break;
        }
      case Op.FORLOOP:
      case Op.FORPREP:
      case Op.TFORPREP:
      case Op.TFORCALL:
      case Op.TFORLOOP:
        /* Do nothing ... handled with branches */
        break;
      case Op.SETLIST50:
      case Op.SETLISTO:
        {
          Expression table = r.getValue(A, line);
          int n = Bx % 32;
          for (int i = 1; i <= n + 1; i++) {
            operations.add(TableSet(line, table, ConstantExpression(Constant(Bx - n + i), -1), r.getExpression(A + i, line), false, r.getUpdated(A + i, line)));
          }
          break;
        }
      case Op.SETLIST:
        {
          if (C == 0) {
            C = code.codepoint(line + 1);
            skip[line + 1] = true;
          }
          if (B == 0) {
            B = registers - A - 1;
          }
          Expression table = r.getValue(A, line);
          for (int i = 1; i <= B; i++) {
            operations.add(TableSet(line, table, ConstantExpression(Constant((C - 1) * 50 + i), -1), r.getExpression(A + i, line), false, r.getUpdated(A + i, line)));
          }
          break;
        }
      case Op.CLOSE:
        break;
      case Op.CLOSURE:
        {
          LFunction f = functions[Bx];
          operations.add(RegisterSet(line, A, ClosureExpression(f, declList, line + 1)));
          if (function.header.version.usesInlineUpvalueDeclarations()) {
            // Skip upvalue declarations
            for (int i = 0; i < f.numUpvalues; i++) {
              skip[line + 1 + i] = true;
            }
          }
          break;
        }
      case Op.VARARG:
        {
          bool multiple = (B != 2);
          if (B == 1) throw StateError();
          if (B == 0) B = registers - A + 1;
          Expression value = Vararg(B - 1, multiple);
          for (int register = A; register <= A + B - 2; register++) {
            operations.add(RegisterSet(line, register, value));
          }
          break;
        }
      default:
        throw StateError('Illegal instruction: ${code.op(line)}');
    }
    return operations;
  }

  void processSequence(int begin, int end) {
    int blockIndex = 1;
    Stack<Block> blockStack = Stack<Block>();
    blockStack.push(blocks[0]);
    skip = List<bool>(end + 1);
    for (int line = begin; line <= end; line++) {
      Operation? blockHandler;
      while (blockStack.peek.end <= line) {
        Block block = blockStack.pop();
        blockHandler = block.process(this);
        if (blockHandler != null) {
          break;
        }
      }
      if (blockHandler == null) {
        while (blockIndex < blocks.length && blocks[blockIndex].begin <= line) {
          blockStack.push(blocks[blockIndex++]);
        }
      }
      Block block = blockStack.peek;
      r.startLine(line);
      if (skip[line]) {
        List<Declaration> newLocals = r.getNewLocals(line);
        if (newLocals.isNotEmpty) {
          Assignment assign = Assignment();
          assign.declare(newLocals[0].begin);
          for (Declaration decl in newLocals) {
            assign.addLast(VariableTarget(decl), r.getValue(decl.register, line));
          }
          blockStack.peek.addStatement(assign);
        }
        continue;
      }
      List<Operation> operations = processLine(line);
      List<Declaration> newLocals = r.getNewLocals(blockHandler == null ? line : line - 1);
      Assignment? assign;
      if (blockHandler == null) {
        if (code.op(line) == Op.LOADNIL) {
          assign = Assignment();
          int count = 0;
          for (Operation operation in operations) {
            RegisterSet set = operation as RegisterSet;
            operation.process(r, block);
            if (r.isAssignable(set.register, set.line)) {
              assign.addLast(r.getTarget(set.register, set.line), set.value);
              count++;
            }
          }
          if (count > 0) {
            block.addStatement(assign);
          }
        } else if (code.op(line) == Op.TFORPREP) {
          newLocals.clear();
        } else {
          for (Operation operation in operations) {
            Assignment? temp = processOperation(operation, line, line + 1, block);
            if (temp != null) {
              assign = temp;
            }
          }
          if (assign != null && assign.getFirstValue().isMultiple()) {
            block.addStatement(assign);
          }
        }
      } else {
        assign = processOperation(blockHandler, line, line, block);
      }
      if (assign != null) {
        if (newLocals.isNotEmpty) {
          assign.declare(newLocals[0].begin);
          for (Declaration decl in newLocals) {
            assign.addLast(VariableTarget(decl), r.getValue(decl.register, line + 1));
          }
        }
      }
      if (blockHandler == null) {
        if (assign != null) {
        } else if (newLocals.isNotEmpty && code.op(line) != Op.FORPREP) {
          if (code.op(line) != Op.JMP || code.op(line + 1 + code.sBx(line)) != tforTarget) {
            assign = Assignment();
            assign.declare(newLocals[0].begin);
            for (Declaration decl in newLocals) {
              assign.addLast(VariableTarget(decl), r.getValue(decl.register, line));
            }
            blockStack.peek.addStatement(assign);
          }
        }
      }
      if (blockHandler != null) {
        line--;
        continue;
      }
    }
  } 
}