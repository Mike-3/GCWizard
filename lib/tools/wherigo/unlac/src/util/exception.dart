class IllegalStateException implements Exception {
  String value = '';

  IllegalStateException([this.value = '']);

  @override
  String toString() => value;
}