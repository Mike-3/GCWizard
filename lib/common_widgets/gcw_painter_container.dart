import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gc_wizard/application/theme/theme.dart';
import 'package:gc_wizard/common_widgets/buttons/gcw_iconbutton.dart';
import 'package:gc_wizard/common_widgets/dividers/gcw_text_divider.dart';
import 'package:zoom_widget/zoom_widget.dart';

class GCWPainterContainer extends StatefulWidget {
  final void Function(double)? onChanged;
  final void Function(double)? onScaleChanged;
  final Widget child;
  final double scale;
  final bool? suppressTopSpace;
  final bool? suppressBottomSpace;

  const GCWPainterContainer(
      {Key? key,
        required this.child,
        this.scale = 1,
        this.suppressTopSpace,
        this.suppressBottomSpace,
        this.onChanged,
        this.onScaleChanged})
      : super(key: key);

  @override
  _GCWPainterContainerState createState() => _GCWPainterContainerState();
}

class _GCWPainterContainerState extends State<GCWPainterContainer> {
  late double _currentScale;
  double _scaleFactor = 1.0;
  double _baseScaleFactor = 1.0;

  @override
  void initState() {
    super.initState();

    _currentScale = widget.scale;
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      GCWTextDivider(
          text: '',
          suppressTopSpace: widget.suppressTopSpace,
          suppressBottomSpace: widget.suppressBottomSpace,
          trailing: Row(children: <Widget>[
            GCWIconButton(
              size: IconButtonSize.SMALL,
              icon: Icons.zoom_in,
              onPressed: () {
                setState(() {
                  _currentScale += 0.1;
                  if (widget.onChanged != null) widget.onChanged!(_currentScale);
                });
              },
            ),
            GCWIconButton(
              size: IconButtonSize.SMALL,
              icon: Icons.zoom_out,
              onPressed: () {
                setState(() {
                  _currentScale = max(0.1, _currentScale - 0.1);
                  if (widget.onChanged != null) widget.onChanged!(_currentScale);
                });
              },
            ),
          ])),
      SingleChildScrollView(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Zoom(
            initTotalZoomOut: true,
            initScale: 1,
            onScaleUpdate: (var1, var2 ) {print('start ' + var1.toString() + ' ' + var2.toString()},

          child: Container(
            constraints: BoxConstraints(
                maxWidth:
                    min(500, min(maxScreenWidth(context) * 0.95, maxScreenHeight(context) * 0.8)) * _currentScale),
                margin: const EdgeInsets.symmetric(vertical: 20.0),


                ),
                // GestureDetector(
                //   child: widget.child,
                //   // onPanDown: (panDown) {print('panDown ' + panDown.localPosition.toString());},
                //   // onTap: () {print('tap ' );},
                //
                //   // onScaleStart: (scaleStartDetails) {
                //   //   print('start ' + _scaleFactor.toString() + " " + scaleStartDetails.pointerCount.toString());
                //   // },
                //   //behavior: () => print('behavior '),
                //
                //   onScaleUpdate: (scaleUpdateDetails) {
                //     _scaleFactor = scaleUpdateDetails.scale;
                //     print('update ' + scaleUpdateDetails.scale.toString());
                //   // don't update the UI if the scale didn't change
                //   // if (scaleUpdateDetails.scale == 1.0) {
                //   // return;
                //   // }
                //   },
                //   onScaleEnd: (scaleEndDetails) {
                //     if (widget.onScaleChanged != null) {
                //       widget.onScaleChanged!(_scaleFactor);
                //       _currentScale *= _scaleFactor;
                //       if (widget.onChanged != null) widget.onChanged!(_currentScale);
                //     }
                //
                //     print('end ' + scaleEndDetails.pointerCount.toString() +' '+ _scaleFactor.toString());
                //   },
                // ),
            ),
        ),
      ),
    ]);
  }
}
