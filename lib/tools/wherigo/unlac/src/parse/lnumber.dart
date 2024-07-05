import 'lnumbertype.dart';

abstract class LNumber {
  static LNumber makeInteger(int number) {
    return LIntNumber(number);
  }

  @override
  String toString();

  //TODO: problem solution for this issue
  double value();
}

class LFloatNumber extends LNumber {
  final double number;
  final NumberMode mode;

  LFloatNumber(this.number, this.mode);

  @override
  String toString() {
    if (mode == NumberMode.MODE_NUMBER && number == number.roundToDouble()) {
      return number.toInt().toString();
    } else {
      return number.toString();
    }
  }

  @override
  bool operator ==(Object o) {
    if (o is LFloatNumber) {
      return number == o.number;
    } else if (o is LNumber) {
      return value() == o.value();
    }
    return false;
  }

  @override
  double value() {
    return number;
  }
}

class LDoubleNumber extends LNumber {
  final double number;
  final NumberMode mode;

  LDoubleNumber(this.number, this.mode);

  @override
  String toString() {
    if (mode == NumberMode.MODE_NUMBER && number == number.roundToDouble()) {
      return number.toInt().toString();
    } else {
      return number.toString();
    }
  }

  @override
  bool operator ==(Object o) {
    if (o is LDoubleNumber) {
      return number == o.number;
    } else if (o is LNumber) {
      return value() == o.value();
    }
    return false;
  }

  @override
  double value() {
    return number;
  }
}

class LIntNumber extends LNumber {
  final int number;

  LIntNumber(this.number);

  @override
  String toString() {
    return number.toString();
  }

  @override
  bool operator ==(Object o) {
    if (o is LIntNumber) {
      return number == o.number;
    } else if (o is LNumber) {
      return value() == o.value();
    }
    return false;
  }

  @override
  double value() {
    return number.toDouble();
  }
}

class LLongNumber extends LNumber {
  final int number;

  LLongNumber(this.number);

  @override
  String toString() {
    return number.toString();
  }

  @override
  bool operator ==(Object o) {
    if (o is LLongNumber) {
      return number == o.number;
    } else if (o is LNumber) {
      return value() == o.value();
    }
    return false;
  }

  @override
  double value() {
    return number.toDouble();
  }
}