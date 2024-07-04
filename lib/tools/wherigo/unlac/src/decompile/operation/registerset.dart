import '../block/block.dart';
import '../expression/expression.dart';
import '../registers.dart';
import '../statement/assignment.dart';
import '../statement/statement.dart';
import 'operation.dart';

class RegisterSet extends Operation {
  final int register;
  final Expression value;

  RegisterSet(int line, this.register, this.value) : super(line);

  @override
  Statement? process(Registers r, Block block) {
    r.setValue(register, line, value);
    if (r.isAssignable(register, line)) {
      return Assignment.withTargetValue(r.getTarget(register, line), value);
    } else {
      return null;
    }
  }
}


