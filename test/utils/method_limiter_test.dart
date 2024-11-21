import "package:flutter_test/flutter_test.dart";
import 'package:gc_wizard/utils/method_limiter.dart';

Future<void> main() async {
  var limiter = MethodLimiter(2);

  Future<void> _doWork(int index) async {
    print('started ' + index.toString());
    Future<int>.delayed(const Duration(milliseconds: 200)).then((value) {
      print('finished ' + index.toString());
    });
  }

  for (var i = 0; i< 10; i++) {
    await limiter.callMethod(() => _doWork(i));
  }
}