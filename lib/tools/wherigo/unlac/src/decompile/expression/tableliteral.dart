import 'dart:math';

import 'package:collection/collection.dart';

import '../decompiler.dart';
import '../output.dart';
import 'expression.dart';

class TableLiteral extends Expression {
  List<Entry> entries;
  bool isObject = true;
  bool isList = true;
  int listLength = 1;
  int capacity;

  TableLiteral(int arraySize, int hashSize)
      : entries = List<Entry>.filled(arraySize + hashSize, Entry(), growable: true),
        capacity = arraySize + hashSize,
        super(Expression.PRECEDENCE_ATOMIC);

  @override
  int getConstantIndex() {
    int index = -1;
    for (var entry in entries.whereNotNull()) {
      index = max(entry.key.getConstantIndex(), index);
      index = max(entry.value.getConstantIndex(), index);
    }
    return index;
  }

  @override
  void print(Decompiler d, Output out) {
    entries.sort();
    listLength = 1;
    if (entries.isEmpty) {
      out.print("{}");
    } else {
      bool lineBreak = isList && entries.length > 5 ||
          isObject && entries.length > 2 ||
          !isObject;
      if (!lineBreak) {
        for (var entry in entries) {
          var value = entry.value;
          if (!(value.isBrief())) {
            lineBreak = true;
            break;
          }
        }
      }
      out.print("{");
      if (lineBreak) {
        out.println();
        out.indent();
      }
      printEntry(d, 0, out);
      if (!entries[0].value.isMultiple()) {
        for (int index = 1; index < entries.length; index++) {
          out.print(",");
          if (lineBreak) {
            out.println();
          } else {
            out.print(" ");
          }
          printEntry(d, index, out);
          if (entries[index].value.isMultiple()) {
            break;
          }
        }
      }
      if (lineBreak) {
        out.println();
        out.dedent();
      }
      out.print("}");
    }
  }

  void printEntry(Decompiler d, int index, Output out) {
    var entry = entries[index];
    var key = entry.key;
    var value = entry.value;
    var isList = entry.isList;
    var multiple = index + 1 >= entries.length || value.isMultiple();
    if (isList && key.isInteger() && listLength == key.asInteger()) {
      if (multiple) {
        value.printMultiple(d, out);
      } else {
        value.print(d, out);
      }
      listLength++;
    } else if (isObject && key.isIdentifier()) {
      out.print(key.asName());
      out.print(" = ");
      value.print(d, out);
    } else {
      out.print("[");
      key.printBraced(d, out);
      out.print("] = ");
      value.print(d, out);
    }
  }

  @override
  bool isTableLiteral() {
    return true;
  }

  @override
  bool isUngrouped() {
    return true;
  }

  @override
  bool isNewEntryAllowed() {
    return entries.length < capacity;
  }

  @override
  void addEntry(Entry entry) {
    entries.add(entry);
    isObject = isObject && (entry.isList || entry.key.isIdentifier());
    isList = isList && entry.isList;
  }

  @override
  bool isBrief() {
    return false;
  }
}

class Entry implements Comparable<Entry> {
  final Expression key;
  final Expression value;
  final bool isList;
  final int timestamp;

  Entry(this.key, this.value, this.isList, this.timestamp);

  @override
  int compareTo(Entry e) {
    return timestamp.compareTo(e.timestamp);
  }
}