part of 'package:gc_wizard/tools/coords/map_view/widget/gcw_mapview.dart';

/// This is the [CustomPainter] that draws the scalebar label and lines
/// onto the canvas.
class GCWMapViewScalebarPainter extends CustomPainter {
  /// marker points
  final List<Offset> scalebarPoints;

  /// width of the scalebar line stroke
  final double strokeWidth;

  /// scalebar line height
  final double lineWidth;

  /// The cached half of the line stroke width
  late final _halfStrokeWidth = strokeWidth / 2;

  final Paint _linePaint = Paint();
  final List<TextPainter> _textPainters;

  /// Create a new [GCWMapViewScalebar], internally used in the [GCWMapViewScalebar].
  GCWMapViewScalebarPainter({
    required this.scalebarPoints,
    required List<TextSpan> texts,
    required this.strokeWidth,
    required this.lineWidth,
    required Color lineColor,
  }) : _textPainters = texts.map((text) => TextPainter(
    text: text,
    textDirection: ui.TextDirection.ltr,
    maxLines: 1,
  )).toList() {
    _linePaint
      ..color = lineColor
      ..strokeCap = StrokeCap.square
      ..strokeWidth = strokeWidth;
    for (var textPainter in _textPainters) {
      textPainter.layout();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    var textY = 18.0;

    // draw text label
    const labelX = 3.0;
    _textPainters[0].paint(
      canvas,
      Offset(max(0, labelX), - textY),
    );
    _textPainters[1].paint(
      canvas,
      Offset(max(0, labelX), scalebarPoints[1].dy - scalebarPoints[0].dy - textY),
    );
    _textPainters[2].paint(
      canvas,
      Offset(max(0, labelX), scalebarPoints[2].dy - scalebarPoints[0].dy - textY),
    );
    _textPainters[3].paint(
      canvas,
      Offset(max(0, labelX), scalebarPoints[3].dy - scalebarPoints[0].dy - textY),
    );

    final length = scalebarPoints[3].dy - scalebarPoints[0].dy;

    final linePoints = Float32List.fromList(<double>[
      //main line
      0.0,
      0.0 - _halfStrokeWidth,
      0.0,
      length - _halfStrokeWidth,

      // bottom marker
      _halfStrokeWidth,
      0.0 - _halfStrokeWidth,
      lineWidth,
      0.0 - _halfStrokeWidth,

      // 1. section
      _halfStrokeWidth,
      scalebarPoints[1].dy - scalebarPoints[0].dy - _halfStrokeWidth,
      lineWidth,
      scalebarPoints[1].dy - scalebarPoints[0].dy - _halfStrokeWidth,

      // 2. section
      _halfStrokeWidth,
      scalebarPoints[2].dy - scalebarPoints[0].dy - _halfStrokeWidth,
      lineWidth,
      scalebarPoints[2].dy - scalebarPoints[0].dy - _halfStrokeWidth,

      // top marker
      _halfStrokeWidth,
      scalebarPoints[3].dy - scalebarPoints[0].dy - _halfStrokeWidth,
      lineWidth,
      scalebarPoints[3].dy - scalebarPoints[0].dy - _halfStrokeWidth,
    ]);

    // draw lines as raw points
    canvas.drawRawPoints(
      ui.PointMode.lines,
      linePoints,
      _linePaint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}