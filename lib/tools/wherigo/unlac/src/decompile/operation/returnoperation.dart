import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/block.dart';
import 'package:unluac/decompile/expression.dart';
import 'package:unluac/decompile/statement.dart';

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


