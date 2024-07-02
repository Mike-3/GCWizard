import '../declaration.dart';
import '../decompiler.dart';
import '../output.dart';

abstract class Target {

  void print(Decompiler d, Output out);
  
  void printMethod(Decompiler d, Output out);
  
  bool isDeclaration(Declaration decl) {
    return false;
  }
  
  bool isLocal() {
    return false;
  }
  
  int? getIndex() {
    throw StateError('Illegal state');
  }
  
  bool isFunctionName() {
    return true;
  }
  
  bool beginsWithParen() {
    return false;
  }
}


