import 'bobject.dart';

class BInteger extends BObject {
  final BigInt? big;
  final int n;

  static BigInt? _maxInt;
  static BigInt? _minInt;

  BInteger(BInteger b)
      : big = b.big,
        n = b.n;

  BInteger.Int(int n)
      : big = null,
        n = n;

  BInteger.BigInt(BigInt big)
      : big = big,
        n = 0 {
    if (_maxInt == null) {
      _maxInt = BigInt.from(int.maxValue);
      _minInt = BigInt.from(int.minValue);
    }
  }

  int asInt() {
    if (big == null) {
      return n;
    } else if (big > _maxInt! || big < _minInt!) {
      throw StateError('The size of an integer is outside the range that unluac can handle.');
    } else {
      return big.toInt();
    }
  }

  void iterate(void Function() thunk) {
    if (big == null) {
      for (int i = n; i > 0; i--) {
        thunk();
      }
    } else {
      BigInt i = big;
      while (i.sign > 0) {
        thunk();
        i -= BigInt.one;
      }
    }
  }
}

