import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/block.dart';
import 'package:unluac/decompile/expression/function_call.dart';
import 'package:unluac/decompile/statement/function_call_statement.dart';
import 'package:unluac/decompile/statement/statement.dart';

class CallOperation extends Operation {
  FunctionCall call;

  CallOperation(int line, this.call) : super(line);

  @override
  Statement process(Registers r, Block block) {
    return FunctionCallStatement(call);
  }
}


