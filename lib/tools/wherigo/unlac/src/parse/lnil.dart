import 'lobject.dart';

class LNil extends LObject {
  static final LNil NIL = LNil._internal();

  LNil._internal();

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }

  @override
  int get hashCode => super.hashCode;
}