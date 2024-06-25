import 'dart:math' as math;

import 'biobjecttype.dart';

class BSizeT extends BInteger {
  BSizeT(BInteger b) : super(b);

  BSizeT(int n) : super(n);

  BSizeT(math.BigInt n) : super(n);
}

