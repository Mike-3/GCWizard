import 'biobjecttype.dart';

class BList<T extends BObject> extends BObject {
  final BInteger length;
  final List<T> values;

  BList(this.length, this.values);

  T get(int index) {
    return values[index];
  }

  List<T> asArray(List<T> array) {
    for (int i = 0; i < values.length; i++) {
      array[i] = values[i];
    }
    return array;
  }
}

