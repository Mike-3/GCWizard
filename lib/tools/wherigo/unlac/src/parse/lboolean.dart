import 'lobject.dart';

class LBoolean extends LObject {
  static final LBoolean LTRUE = LBoolean(true);
  static final LBoolean LFALSE = LBoolean(false);

  final bool value;

  LBoolean(this.value);

  @override
  String toString() {
    return value.toString();
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other);
  }
}

