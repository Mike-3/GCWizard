import '../parse/llocal.dart';

class Declaration {
  final String name;
  final int begin;
  final int end;
  int? register;

  /// Whether this is an invisible for-loop book-keeping variable.
  bool forLoop = false;

  /// Whether this is an explicit for-loop declared variable.
  bool forLoopExplicit = false;

  Declaration(LLocal local)
      : name = local.toString(),
        begin = local.start,
        end = local.end;

  Declaration.withParams(this.name, this.begin, this.end);
}