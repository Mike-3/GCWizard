import 'dart:isolate';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gc_wizard/application/i18n/logic/app_localizations.dart';
import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer_parameters.dart';
import 'package:gc_wizard/common_widgets/buttons/gcw_button.dart';
import 'package:gc_wizard/utils/complex_return_types.dart';

Isolate? _isolate;

const double GCW_ASYNC_EXECUTER_INDICATOR_HEIGHT = 230;
const double GCW_ASYNC_EXECUTER_INDICATOR_WIDTH = 150;

class GCWAsyncExecuter<T> extends StatefulWidget {
  final Future<T> Function(GCWAsyncExecuterParameters) isolatedFunction;
  final Future<GCWAsyncExecuterParameters?> Function() parameter;
  final void Function(T) onReady;
  final bool isOverlay;

  const GCWAsyncExecuter({
    super.key,
    required this.isolatedFunction,
    required this.parameter,
    required this.onReady,
    this.isOverlay = true,
  });

  @override
  _GCWAsyncExecuterState<T> createState() => _GCWAsyncExecuterState<T>();
}

Future<ReceivePort> _makeIsolate(
    void Function(GCWAsyncExecuterParameters) isolatedFunction, GCWAsyncExecuterParameters parameters) async {
  ReceivePort receivePort = ReceivePort();
  parameters.sendAsyncPort = receivePort.sendPort;

  _isolate = await Isolate.spawn(isolatedFunction, parameters);

  return receivePort;
}

class _GCWAsyncExecuterState<T> extends State<GCWAsyncExecuter<T>> {
  T? _result;
  bool isOverlay = true;
  bool _cancel = false;
  ReceivePort? _receivePort;

  _GCWAsyncExecuterState();

  @override
  void initState() {
    super.initState();
    isOverlay = widget.isOverlay;
  }

  @override
  void dispose() {
    _cancelProcess(); // Beende alle Ressourcen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Stream<double> progress() async* {
      var parameter = await widget.parameter();
      if (!_cancel && parameter != null) {
        if (kIsWeb) {
          _result = await widget.isolatedFunction(parameter);
          return;
        } else {
          _receivePort = await _makeIsolate(widget.isolatedFunction, parameter);
        }
        if (_cancel) {
          _cancelProcess();
          return;
        }

        await for (var event in _receivePort!) {
          if (_cancel) {
            _cancelProcess();
            break;
          }
          if (event is DoubleText && event.text == PROGRESS) {
            yield event.value;
          } else if (event is T) {
            _result = event;
            _receivePort!.close();
            break;
          }
        }
      }
    }

    return StreamBuilder(
        stream: progress(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (widget.isOverlay) {
              Navigator.of(context).pop(); // Pop from dialog on completion (needen on overlay)
              _cancelProcess();
            }
            if (_result is T) {
              widget.onReady(_result as T);
            }
          }
          return Column(children: <Widget>[
            (snapshot.hasData && snapshot.data is double)
                ? Expanded(
                    child: Stack(fit: StackFit.expand, children: [
                    CircularProgressIndicator(
                      value: snapshot.data as double,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                      strokeWidth: 20,
                    ),
                    Positioned(
                      child: Center(
                        child: Text(
                          ((snapshot.data as double) * 100).toStringAsFixed(0).toString() + '%',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white, decoration: TextDecoration.none),
                        ),
                      ),
                    ),
                  ]))
                : const Expanded(
                    child: Stack(fit: StackFit.expand, children: [
                    CircularProgressIndicator(
                      backgroundColor: Colors.white,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      strokeWidth: 20,
                    )
                  ])),
            const SizedBox(height: 10),
            GCWButton(
              text: i18n(context, 'common_cancel'),
              onPressed: () {
                _cancelProcess();
                _cancel = true;
              },
            )
          ]);
        });
  }

  void _cancelProcess() {
    if (_isolate != null) {
      _isolate!.kill(priority: Isolate.immediate);
      _isolate = null;
    }
    if (_receivePort != null) {
      _receivePort!.close();
      _receivePort = null;
    }
  }
}
