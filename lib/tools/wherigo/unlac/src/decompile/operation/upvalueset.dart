import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/block.dart';
import 'package:unluac/decompile/expression.dart';
import 'package:unluac/decompile/statement.dart';
import 'package:unluac/decompile/target.dart';

class UpvalueSet extends Operation {
  UpvalueTarget target;
  Expression value;

  UpvalueSet(int line, String upvalue, Expression value) : super(line) {
    target = UpvalueTarget(upvalue);
    this.value = value;
  }

  @override
  Statement process(Registers r, Block block) {
    return Assignment(target, value);
  }
}


