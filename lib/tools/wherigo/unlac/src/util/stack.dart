
class Stack<T> {
  final List<T> _data;

  Stack() : _data = [];

  bool get isEmpty => _data.isEmpty;

  T get peek => _data.last;

  T pop() => _data.removeLast();

  void push(T item) {
    if (_data.length > 65536) {
      throw IndexError(_data.length, _data, 'Trying to push more than 65536 items!');
    }
    _data.add(item);
  }

  int get size => _data.length;

  void reverse() {
    _data.reversed.toList();
  }
}