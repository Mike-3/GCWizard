import 'package:unluac/decompile/registers.dart';
import 'package:unluac/decompile/block.dart';
import 'package:unluac/decompile/expression.dart';
import 'package:unluac/decompile/statement.dart';
import 'package:unluac/decompile/target.dart';

class TableSet extends Operation {
  Expression table;
  Expression index;
  Expression value;
  bool isTable;
  int timestamp;

  TableSet(int line, this.table, this.index, this.value, this.isTable, this.timestamp) : super(line);

  @override
  Statement process(Registers r, Block block) {
    // .isTableLiteral() is sufficient when there is debugging info
    if (table.isTableLiteral() && (value.isMultiple() || table.isNewEntryAllowed())) {
      table.addEntry(TableLiteral.Entry(index, value, !isTable, timestamp));
      return null;
    } else {
      return Assignment(TableTarget(table, index), value);
    }
  }
}


