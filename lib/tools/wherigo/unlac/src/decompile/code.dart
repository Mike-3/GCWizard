import '../parse/lfunction.dart';
import 'codeextract.dart';
import 'op.dart';
import 'opcodemap.dart';

class Code {
  late final CodeExtract extractor;
  late final OpcodeMap map;
  late final List<int> code;

  Code(LFunction function) {
    this.code = function.code;
    this.map = function.header.version.getOpcodeMap();
    this.extractor = function.header.extractor;
  }

  // bool reentered = false;

  Op op(int line) {
    // if (!reentered) {
    //   reentered = true;
    //   print('line $line: ${toString(line)}');
    //   reentered = false;
    // }
    return map[opcode(line)]!;
  }

  int opcode(int line) {
    return code[line - 1] & 0x0000003F;
  }

  int A(int line) {
    return extractor.extract_A(code[line - 1]);
  }

  int C(int line) {
    return extractor.extract_C(code[line - 1]);
  }

  int B(int line) {
    return extractor.extract_B(code[line - 1]);
  }

  int Bx(int line) {
    return extractor.extract_Bx(code[line - 1]);
  }

  int sBx(int line) {
    return extractor.extract_sBx(code[line - 1]);
  }

  int codepoint(int line) {
    return code[line - 1];
  }

  int get length {
    return code.length;
  }

  String toString(int line) {
    return op(line).codePointToString(codepoint(line), extractor);
  }
}

