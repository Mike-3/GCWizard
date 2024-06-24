import 'decompile/op.dart';
import 'decompile/opcodemap.dart';
import 'parse/lheadertype.dart';

abstract class Version {
  static final Version LUA50 = Version50();
  static final Version LUA51 = Version51();
  static final Version LUA52 = Version52();
  static final Version LUA53 = Version53();

  final int versionNumber;

  Version(this.versionNumber);

  LHeaderType getLHeaderType();

  OpcodeMap getOpcodeMap() {
    return OpcodeMap(versionNumber);
  }

  int getOuterBlockScopeAdjustment();

  bool usesOldLoadNilEncoding();

  bool usesInlineUpvalueDeclarations();

  Op getTForTarget();

  Op? getForTarget();

  bool isBreakableLoopEnd(Op op);

  bool isAllowedPreceedingSemicolon();

  bool isEnvironmentTable(String name);
}

class Version50 extends Version {
  Version50() : super(0x50);

  @override
  LHeaderType getLHeaderType() {
    return LHeaderType.TYPE50;
  }

  @override
  int getOuterBlockScopeAdjustment() {
    return -1;
  }

  @override
  bool usesOldLoadNilEncoding() {
    return true;
  }

  @override
  bool usesInlineUpvalueDeclarations() {
    return true;
  }

  @override
  Op getTForTarget() {
    return Op.TFORLOOP;
  }

  @override
  Op getForTarget() {
    return Op.FORLOOP;
  }

  @override
  bool isBreakableLoopEnd(Op op) {
    return op == Op.JMP || op == Op.FORLOOP;
  }

  @override
  bool isAllowedPreceedingSemicolon() {
    return false;
  }

  @override
  bool isEnvironmentTable(String upvalue) {
    return false;
  }
}

class Version51 extends Version {
  Version51() : super(0x51);

  @override
  LHeaderType getLHeaderType() {
    return LHeaderType.TYPE51;
  }

  @override
  int getOuterBlockScopeAdjustment() {
    return -1;
  }

  @override
  bool usesOldLoadNilEncoding() {
    return true;
  }

  @override
  bool usesInlineUpvalueDeclarations() {
    return true;
  }

  @override
  Op getTForTarget() {
    return Op.TFORLOOP;
  }

  @override
  Op? getForTarget() {
    return null;
  }

  @override
  bool isBreakableLoopEnd(Op op) {
    return op == Op.JMP || op == Op.FORLOOP;
  }

  @override
  bool isAllowedPreceedingSemicolon() {
    return false;
  }

  @override
  bool isEnvironmentTable(String upvalue) {
    return false;
  }
}

class Version52 extends Version {
  Version52() : super(0x52);

  @override
  LHeaderType getLHeaderType() {
    return LHeaderType.TYPE52;
  }

  @override
  int getOuterBlockScopeAdjustment() {
    return 0;
  }

  @override
  bool usesOldLoadNilEncoding() {
    return false;
  }

  @override
  bool usesInlineUpvalueDeclarations() {
    return false;
  }

  @override
  Op getTForTarget() {
    return Op.TFORCALL;
  }

  @override
  Op? getForTarget() {
    return null;
  }

  @override
  bool isBreakableLoopEnd(Op op) {
    return op == Op.JMP || op == Op.FORLOOP || op == Op.TFORLOOP;
  }

  @override
  bool isAllowedPreceedingSemicolon() {
    return true;
  }

  @override
  bool isEnvironmentTable(String name) {
    return name == "_ENV";
  }
}

class Version53 extends Version {
  Version53() : super(0x53);

  @override
  LHeaderType getLHeaderType() {
    return LHeaderType.TYPE53;
  }

  @override
  int getOuterBlockScopeAdjustment() {
    return 0;
  }

  @override
  bool usesOldLoadNilEncoding() {
    return false;
  }

  @override
  bool usesInlineUpvalueDeclarations() {
    return false;
  }

  @override
  Op getTForTarget() {
    return Op.TFORCALL;
  }

  @override
  Op? getForTarget() {
    return null;
  }

  @override
  bool isBreakableLoopEnd(Op op) {
    return op == Op.JMP || op == Op.FORLOOP || op == Op.TFORLOOP;
  }

  @override
  bool isAllowedPreceedingSemicolon() {
    return true;
  }

  @override
  bool isEnvironmentTable(String name) {
    return name == "_ENV";
  }
}


