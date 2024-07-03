import '../block/block.dart';
import '../expression/functioncall.dart';
import '../registers.dart';
import '../statement/functioncallstatement.dart';
import '../statement/statement.dart';
import 'operation.dart';

class CallOperation extends Operation {
  FunctionCall call;

  CallOperation(int line, this.call) : super(line);

  @override
  Statement process(Registers r, Block block) {
    return FunctionCallStatement(call);
  }
}


