import 'dart:io';

abstract class OutputProvider {
  void print(String s);
  void printByte(int b);
  void println();
}

class Output {
  OutputProvider out;
  int indentationLevel = 0;
  int position = 0;

  Output() : this(_DefaultOutputProvider());

  Output.withProvider(this.out);

  void indent() {
    indentationLevel += 2;
  }

  void dedent() {
    indentationLevel -= 2;
  }

  int getIndentationLevel() {
    return indentationLevel;
  }

  int getPosition() {
    return position;
  }

  void setIndentationLevel(int indentationLevel) {
    this.indentationLevel = indentationLevel;
  }

  void _start() {
    if (position == 0) {
      for (int i = indentationLevel; i != 0; i--) {
        out.print(" ");
        position++;
      }
    }
  }

  void print(String s) {
    _start();
    out.print(s);
    position += s.length;
  }

  void printByte(int b) {
    _start();
    out.printByte(b);
    position += 1;
  }

  void println() {
    _start();
    out.println();
    position = 0;
  }

  void printlnWithText(String s) {
    print(s);
    println();
  }
}

class _DefaultOutputProvider implements OutputProvider {
  @override
  void print(String s) {
    stdout.write(s);
  }

  @override
  void printByte(int b) {
    stdout.add([b]);
  }

  @override
  void println() {
    stdout.writeln();
  }
}