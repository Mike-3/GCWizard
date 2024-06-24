import 'package:unluac/decompile/decompiler.dart';
import 'package:unluac/decompile/output.dart';
import 'package:unluac/decompile/statement.dart';
import 'package:unluac/parse/lfunction.dart';

class BooleanIndicator extends Block {
  BooleanIndicator(LFunction function, int line) : super(function, line, line);

  @override
  void addStatement(Statement statement) {
    // No implementation needed
  }

  @override
  bool isContainer() {
    return false;
  }

  @override
  bool isUnprotected() {
    return false;
  }

  @override
  bool breakable() {
    return false;
  }

  @override
  int getLoopback() {
    throw StateError('Illegal state');
  }

  @override
  void print(Decompiler d, Output out) {
    out.print('-- unhandled boolean indicator');
  }
}