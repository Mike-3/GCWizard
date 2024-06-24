import 'bobject.dart';

class LUpvalue extends BObject {
  late bool instack;
  late int idx;
  String? name;

  @override
  bool operator ==(Object other) {
    if (other is LUpvalue) {
      return instack == other.instack &&
          idx == other.idx &&
          (name == other.name || (name != null && name == other.name));
    }
    return false;
  }
}

