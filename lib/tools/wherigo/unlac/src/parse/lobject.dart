import 'bobject.dart';

abstract class LObject extends BObject {

  String deref() {
    throw StateError('Illegal state');
  }

  @override
  bool operator ==(Object other);

}