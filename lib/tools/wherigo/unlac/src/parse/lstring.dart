import 'lobject.dart';

class LString extends LObject {
  final int size;
  final String value;

  LString(this.size, String value)
      : value = value.isEmpty ? "" : value.substring(0, value.length - 1);

  @override
  String deref() {
    return value;
  }

  @override
  String toString() {
    return "\"$value\"";
  }

  @override
  bool operator ==(Object o) {
    if (o is LString) {
      return o.value == value;
    }
    return false;
  }

  @override
  int get hashCode => value.hashCode;
}