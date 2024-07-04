import '../block/block.dart';
import '../expression/expression.dart';
import '../registers.dart';
import '../statement/assignment.dart';
import '../statement/statement.dart';
import '../target/globaltarget.dart';
import 'operation.dart';

class GlobalSet extends Operation {
  String global;
  Expression value;

  GlobalSet(int line, this.global, this.value) : super(line);

  @override
  Statement process(Registers r, Block block) {
    return Assignment.withTargetValue(GlobalTarget(global), value);
  }
}


