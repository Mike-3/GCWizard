import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/block.dart';
import 'package:unluac/decompile/expression.dart';
import 'package:unluac/decompile/statement.dart';

class RegisterSet extends Operation {
  final int register;
  final Expression value;

  RegisterSet(int line, this.register, this.value) : super(line);

  @override
  Statement? process(Registers r, Block block) {
    r.setValue(register, line, value);
    if (r.isAssignable(register, line)) {
      return Assignment(r.getTarget(register, line), value);
    } else {
      return null;
    }
  }
}


