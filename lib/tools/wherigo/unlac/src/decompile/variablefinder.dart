import 'dart:core';
import 'dart:math';

import '../parse/lfunction.dart';
import '../parse/lupvalue.dart';
import 'code.dart';
import 'declaration.dart';
import 'decompiler.dart';
import 'op.dart';

class VariableFinder {
    static bool isConstantReference(int value) {
    return (value & 0x100) != 0;
  }

  static List<Declaration> process(Decompiler d, int args, int registers) {
    Code code = d.code;
    RegisterStates states = RegisterStates(registers, code.length);
    List<bool> skip = List.filled(code.length, false);
    for (int line = 1; line <= code.length; line++) {
      if (skip[line - 1]) continue;
      switch (code.op(line)) {
        case Op.MOVE:
          states.get(code.A(line), line).written = true;
          states.get(code.B(line), line).read = true;
          states.setLocal(min(code.A(line), code.B(line)), line);
          break;
        case Op.LOADK:
        case Op.LOADBOOL:
        case Op.GETUPVAL:
        case Op.GETGLOBAL:
        case Op.NEWTABLE:
        case Op.NEWTABLE50:
          states.get(code.A(line), line).written = true;
          break;
        case Op.LOADNIL:
          for (int register = code.A(line); register <= code.B(line); register++) {
            states.get(register, line).written = true;
          }
          break;
        case Op.GETTABLE:
          states.get(code.A(line), line).written = true;
          if (!isConstantReference(code.B(line))) states.get(code.B(line), line).read = true;
          if (!isConstantReference(code.C(line))) states.get(code.C(line), line).read = true;
          break;
        case Op.SETGLOBAL:
        case Op.SETUPVAL:
          states.get(code.A(line), line).read = true;
          break;
        case Op.SETTABLE:
        case Op.ADD:
        case Op.SUB:
        case Op.MUL:
        case Op.DIV:
        case Op.MOD:
        case Op.POW:
          states.get(code.A(line), line).read = true;
          if (!isConstantReference(code.B(line))) states.get(code.B(line), line).read = true;
          if (!isConstantReference(code.C(line))) states.get(code.C(line), line).read = true;
          break;
        case Op.SELF:
          states.get(code.A(line), line).written = true;
          states.get(code.A(line) + 1, line).written = true;
          states.get(code.B(line), line).read = true;
          if (!isConstantReference(code.C(line))) states.get(code.C(line), line).read = true;
          break;
        case Op.UNM:
        case Op.NOT:
        case Op.LEN:
          states.get(code.A(line), line).written = true;
          states.get(code.B(line), line).read = true;
          break;
        case Op.CONCAT:
          states.get(code.A(line), line).written = true;
          for (int register = code.B(line); register <= code.C(line); register++) {
            states.get(register, line).read = true;
            states.setTemporary(register, line);
          }
          break;
        case Op.SETLIST:
          states.setTemporary(code.A(line) + 1, line);
          break;
        case Op.JMP:
          break;
        case Op.EQ:
        case Op.LT:
        case Op.LE:
          if (!isConstantReference(code.B(line))) states.get(code.B(line), line).read = true;
          if (!isConstantReference(code.C(line))) states.get(code.C(line), line).read = true;
          break;
        case Op.TEST:
          states.get(code.A(line), line).read = true;
          break;
        case Op.TESTSET:
          states.get(code.A(line), line).written = true;
          states.get(code.B(line), line).read = true;
          break;
        case Op.CLOSURE:
          LFunction f = d.function.functions[code.Bx(line)];
          for (LUpvalue upvalue in f.upvalues) {
            if (upvalue.instack) {
              states.setLocal(upvalue.idx, line);
            }
          }
          break;
        case Op.CALL:
        case Op.TAILCALL:
          int B = code.B(line);
          int C = code.C(line);
          if (code.op(line) != Op.TAILCALL) {
            if (C >= 2) {
              for (int register = code.A(line); register <= code.A(line) + C - 2; register++) {
                states.get(register, line).written = true;
              }
            }
          }
          for (int register = code.A(line); register <= code.A(line) + B - 1; register++) {
            states.get(code.A(line), line).read = true;
            states.setTemporary(code.A(line), line);
          }
          if (C >= 2) {
            int nline = line + 1;
            int register = code.A(line) + C - 2;
            while (register >= code.A(line) && nline <= code.length) {
              if (code.op(nline) == Op.MOVE && code.B(nline) == register) {
                states.get(code.A(nline), nline).written = true;
                states.get(code.B(nline), nline).read = true;
                states.setLocal(code.A(nline), nline);
                skip[nline - 1] = true;
              }
              register--;
              nline++;
            }
          }
          break;
        default:
      }
    }
    List<Declaration> declList = [];
    for (int register = 0; register < registers; register++) {
      String id = "L";
      bool local = false;
      bool temporary = false;
      int read = 0;
      int written = 0;
      if (register < args) {
        local = true;
        id = "A";
      }
      if (!local && !temporary) {
        for (int line = 1; line <= code.length; line++) {
          RegisterState state = states.get(register, line);
          if (state.local) local = true;
          if (state.temporary) temporary = true;
          if (state.read) read++;
          if (state.written) written++;
        }
      }
      if (!local && !temporary) {
        if (read >= 2 || read == 0) {
          local = true;
        }
      }
      if (local) {
        Declaration decl = Declaration.withParams(
            id + register.toString() + "_" + lc.toString(),
            0,
            code.length + d.getVersion().getOuterBlockScopeAdjustment());
        decl.register = register;
        lc++;
        declList.add(decl);
      }
    }
    return declList;
  }

  static int lc = 0;

  VariableFinder._();
}

class RegisterState {
  bool temporary;
  bool local;
  bool read;
  bool written;

  RegisterState()
      : temporary = false,
        local = false,
        read = false,
        written = false;
}

class RegisterStates {
  int registers;
  int lines;
  late List<List<RegisterState>> states;

  RegisterStates(this.registers, this.lines) {
    states = List.generate(
        lines, (_) => List.generate(registers, (_) => RegisterState()));
  }

  RegisterState get(int register, int line) {
    return states[line - 1][register];
  }

  void setLocal(int register, int line) {
    for (int r = 0; r <= register; r++) {
      get(r, line).local = true;
    }
  }

  void setTemporary(int register, int line) {
    for (int r = register; r < registers; r++) {
      get(r, line).temporary = true;
    }
  }
}


