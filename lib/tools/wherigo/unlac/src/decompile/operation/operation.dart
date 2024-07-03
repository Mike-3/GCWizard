import '../block/block.dart';
import '../registers.dart';
import '../statement/statement.dart';

abstract class Operation {
  final int line;

  Operation(this.line);

  Statement? process(Registers r, Block block);
}


