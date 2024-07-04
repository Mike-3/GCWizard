import '../block/block.dart';
import '../expression/expression.dart';
import '../expression/tableliteral.dart';
import '../registers.dart';
import '../statement/assignment.dart';
import '../statement/statement.dart';
import '../target/tabletarget.dart';
import 'operation.dart';

class TableSet extends Operation {
  Expression table;
  Expression index;
  Expression value;
  bool isTable;
  int timestamp;

  TableSet(int line, this.table, this.index, this.value, this.isTable, this.timestamp) : super(line);

  @override
  Statement? process(Registers r, Block block) {
    // .isTableLiteral() is sufficient when there is debugging info
    if (table.isTableLiteral() && (value.isMultiple() || table.isNewEntryAllowed())) {
      table.addEntry(Entry(index, value, !isTable, timestamp));
      return null;
    } else {
      return Assignment.withTargetValue(TableTarget(table, index), value);
    }
  }
}


