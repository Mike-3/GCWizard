import '../decompiler.dart';
import '../expression/functioncall.dart';
import '../output.dart';

class FunctionCallStatement extends Statement {
  final FunctionCall call;

  FunctionCallStatement(this.call);

  @override
  void print(Decompiler d, Output out) {
    call.print(d, out);
  }

  @override
  bool beginsWithParen() {
    return call.beginsWithParen();
  }
}