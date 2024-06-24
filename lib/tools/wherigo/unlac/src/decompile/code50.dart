import 'codeextract.dart';

class Code50 implements CodeExtract {
  late int shiftA;
  late int shiftB;
  late int shiftBx;
  late int shiftC;
  late int maskOp;
  late int maskA;
  late int maskB;
  late int maskBx;
  late int maskC;
  late int excessK;

  Code50(int sizeOp, int sizeA, int sizeB, int sizeC) {
    shiftC = sizeOp;
    shiftB = sizeC + sizeOp;
    shiftBx = sizeOp;
    shiftA = sizeB + sizeC + sizeOp;
    maskOp = (1 << sizeOp) - 1;
    maskA = (1 << sizeA) - 1;
    maskB = (1 << sizeB) - 1;
    maskBx = (1 << (sizeB + sizeC)) - 1;
    maskC = (1 << sizeC) - 1;
    excessK = maskBx ~/ 2;
  }

  @override
  int extract_A(int codepoint) {
    return (codepoint >> shiftA) & maskA;
  }

  @override
  int extract_C(int codepoint) {
    return (codepoint >> shiftC) & maskC;
  }

  @override
  int extract_B(int codepoint) {
    return (codepoint >> shiftB) & maskB;
  }

  @override
  int extract_Bx(int codepoint) {
    return (codepoint >> shiftBx) & maskBx;
  }

  @override
  int extract_sBx(int codepoint) {
    return ((codepoint >> shiftBx) & maskBx) - excessK;
  }

  @override
  int extract_op(int codepoint) {
    return codepoint & maskOp;
  }
}

