import '../block/block.dart';
import '../expression/expression.dart';
import '../registers.dart';
import '../statement/return.dart';
import '../statement/statement.dart';
import 'operation.dart';

class ReturnOperation extends Operation {
  List<Expression> values;

  ReturnOperation(int line, Expression value) : super(line) {
    values = [value];
  }

  ReturnOperation.withValues(int line, List<Expression> values) : super(line) {
    this.values = values;
  }

  @override
  Statement process(Registers r, Block block) {
    return Return(values);
  }
}


