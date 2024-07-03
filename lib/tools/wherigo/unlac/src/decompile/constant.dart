import '../parse/lboolean.dart';
import '../parse/lnil.dart';
import '../parse/lnumber.dart';
import '../parse/lobject.dart';
import '../parse/lstring.dart';
import 'decompiler.dart';
import 'output.dart';

class Constant {
  static final Set<String> reservedWords = {
    "and",
    "break",
    "do",
    "else",
    "elseif",
    "end",
    "false",
    "for",
    "function",
    "if",
    "in",
    "local",
    "nil",
    "not",
    "or",
    "repeat",
    "return",
    "then",
    "true",
    "until",
    "while"
  };

  final int type;
  final bool boolValue;
  final LNumber? number;
  final String? string;

  Constant.intConstant(int constant)
      : type = 2,
        boolValue = false,
        number = LNumber.makeInteger(constant),
        string = null;

  Constant(LObject constant)
      : type = constant is LNil
      ? 0
      : constant is LBoolean
      ? 1
      : constant is LNumber
      ? 2
      : constant is LString
      ? 3
      : throw ArgumentError("Illegal constant type: $constant"),
        boolValue = constant is LBoolean ? constant == LBoolean.LTRUE : false,
        number = constant is LNumber ? constant : null,
        string = constant is LString ? constant.deref() : null;

  void print(Decompiler d, Output out, bool braced) {
    switch (type) {
      case 0:
        out.print("nil");
        break;
      case 1:
        out.print(boolValue ? "true" : "false");
        break;
      case 2:
        out.print(number.toString());
        break;
      case 3:
        int newlines = 0;
        int unprintable = 0;
        bool rawstring = d.getConfiguration().rawstring;
        for (int i = 0; i < string!.length; i++) {
          var c = string![i];
          if (c == '\n') {
            newlines++;
          } else if ((c.codeUnitAt(0) <= 31 && c != '\t') || c.codeUnitAt(0) >= 127) {
            unprintable++;
          }
        }
        if (unprintable == 0 && (newlines > 1 || (newlines == 1 && string!.indexOf('\n') != string!.length - 1))) {
          int pipe = 0;
          if (string![string!.length - 1] == ']') {
            pipe = 1;
          }
          String pipeString = "]]";
          while (string!.contains(pipeString)) {
            pipe++;
            pipeString = "]${"=" * pipe}]";
          }
          if (braced) out.print("(");
          out.print("[${"=" * pipe}[");
          int indent = out.getIndentationLevel();
          out.setIndentationLevel(0);
          out.println();
          out.print(string!);
          out.print("]${"=" * pipe}]");
          if (braced) out.print(")");
          out.setIndentationLevel(indent);
        } else {
          out.print("\"");
          for (int i = 0; i < string!.length; i++) {
            var c = string!.codeUnitAt(i);
            if (c <= 31 || c >= 127) {
              if (c == 7) {
                out.print("\\a");
              } else if(c == 8) {
                out.print("\\b");
              } else if (c == 12) {
                out.print("\\f");
              } else if (c == 10) {
                out.print("\\n");
              } else if (c == 13) {
                out.print("\\r");
              } else if (c == 9) {
                out.print("\\t");
              } else if (c == 11) {
                out.print("\\v");
              } else if (!rawstring || c <= 127) {
                String dec = c.toString();
                int len = dec.length;
                out.print("\\");
                while (len++ < 3) {
                  out.print("0");
                }
                out.print(dec);
              } else {
                out.print(c.toString());
              }
            } else if(c == 34) {
              out.print("\\\"");
            } else if(c == 92) {
              out.print("\\\\");
            } else {
              out.print(String.fromCharCodes([c]));
            }
          }
          out.print("\"");
        }
        break;
      default:
        throw StateError("Invalid state");
    }
  }

  bool isNil() => type == 0;

  bool isBoolean() => type == 1;

  bool isNumber() => type == 2;

  bool isInteger() => number!.value() == number!.value().round();

  int asInteger() {
    if (!isInteger()) {
      throw StateError("Not an integer");
    }
    return number!.value().toInt();
  }

  bool isString() => type == 3;

  bool isIdentifier() {
    if (!isString()) {
      return false;
    }
    if (reservedWords.contains(string)) {
      return false;
    }
    if (string!.isEmpty) {
      return false;
    }
    var start = string![0];
    if (start != '_' && !RegExp(r'^[a-zA-Z]$').hasMatch(start)) {
      return false;
    }
    for (int i = 1; i < string!.length; i++) {
      var next = string![i];
      if (RegExp(r'^[a-zA-Z0-9_]$').hasMatch(next)) {
        continue;
      }
      return false;
    }
    return true;
  }

  String asName() {
    if (type != 3) {
      throw StateError("Not a string");
    }
    return string!;
  }
}