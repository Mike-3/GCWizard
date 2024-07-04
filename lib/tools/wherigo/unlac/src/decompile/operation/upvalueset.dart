import '../block/block.dart';
import '../expression/expression.dart';
import '../registers.dart';
import '../statement/assignment.dart';
import '../statement/statement.dart';
import '../target/upvaluetarget.dart';
import 'operation.dart';

class UpvalueSet extends Operation {
  late UpvalueTarget target;
  late Expression value;

  UpvalueSet(int line, String upvalue, Expression value) : super(line) {
    target = UpvalueTarget(upvalue);
    this.value = value;
  }

  @override
  Statement process(Registers r, Block block) {
    return Assignment.withTargetValue(target, value);
  }
}


