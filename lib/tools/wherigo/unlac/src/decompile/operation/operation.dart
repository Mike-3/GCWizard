import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/block.dart';
import 'package:unluac/decompile/expression.dart';
import 'package:unluac/decompile/statement.dart';
import 'package:unluac/decompile/target.dart';

class GlobalSet extends Operation {
  String global;
  Expression value;

  GlobalSet(int line, this.global, this.value) : super(line);

  @override
  Statement process(Registers r, Block block) {
    return Assignment(GlobalTarget(global), value);
  }
}


