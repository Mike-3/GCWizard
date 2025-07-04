import 'package:flutter/material.dart';

// source: https://hillel.dev/2018/08/15/flutter-how-to-rebuild-the-entire-app-to-change-the-theme-or-locale/
class AppBuilder extends StatefulWidget {
  final MaterialApp Function(BuildContext) builder;

  const AppBuilder({super.key, required this.builder});

  @override
  _AppBuilderState createState() => _AppBuilderState();

  static _AppBuilderState of(BuildContext context) {
    var newState = context.findAncestorStateOfType<_AppBuilderState>();
    if (newState == null) {
      throw Exception('No AppBuilderState created');
    }

    return newState;
  }
}

class _AppBuilderState extends State<AppBuilder> {
  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }

  void rebuild() {
    setState(() {});
  }
}
