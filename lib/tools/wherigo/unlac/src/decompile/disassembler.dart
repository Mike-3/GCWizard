import '../parse/lfunction.dart';
import 'code.dart';
import 'output.dart';

class Disassembler {
  final LFunction function;
  final Code code;

  Disassembler(this.function) : code = Code(function);

  void disassemble(Output out) {
    disassembleWithLevel(out, 0, 0);
  }

  void disassembleWithLevel(Output out, int level, int index) {
    out.printlnWithText('function $level $index');
    for (int line = 1; line <= function.code.length; line++) {
      out.printlnWithText('\t${code.opcode(line)} ${code.A(line)} ${code.B(line)} ${code.C(line)} ${code.Bx(line)} ${code.sBx(line)} ${code.codepoint(line)}');
    }
    out.println();
    for (int constant = 1; constant <= function.constants.length; constant++) {
      out.printlnWithText('\t$constant ${function.constants[constant - 1]}');
    }
    out.println();
    int subindex = 0;
    for (LFunction child in function.functions) {
      Disassembler(child).disassembleWithLevel(out, level + 1, subindex++);
    }
  }
}