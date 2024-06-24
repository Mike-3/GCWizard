import 'dart:io';

abstract class Statement {
  /// Prints out a sequence of statements on separate lines. Correctly
  /// informs the last statement that it is last in a block.
  static void printSequence(Decompiler d, IOSink out, List<Statement> stmts) {
    int n = stmts.length;
    for (int i = 0; i < n; i++) {
      bool last = (i + 1 == n);
      Statement stmt = stmts[i];
      if (stmt.beginsWithParen() && (i > 0 || d.version.isAllowedPreceedingSemicolon())) {
        out.write(";");
      }
      if (last) {
        stmt.printTail(d, out);
      } else {
        stmt.print(d, out);
      }
      if (!(stmt is IfThenElseBlock)) {
        out.writeln();
      }
    }
  }

  void print(Decompiler d, IOSink out);

  void printTail(Decompiler d, IOSink out) {
    print(d, out);
  }

  String? comment;

  void addComment(String comment) {
    this.comment = comment;
  }

  bool beginsWithParen() {
    return false;
  }
}

class Decompiler {
  final Version version;

  Decompiler(this.version);
}

class Version {
  bool isAllowedPreceedingSemicolon() {
    // Implement the logic for checking if preceding semicolon is allowed
    return true;
  }
}

class IfThenElseBlock extends Statement {
  @override
  void print(Decompiler d, IOSink out) {
    // Implement the print logic for IfThenElseBlock
  }
}