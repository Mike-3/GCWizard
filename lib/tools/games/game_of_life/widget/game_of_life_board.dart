import 'package:flutter/material.dart';
import 'package:gc_wizard/application/theme/theme_colors.dart';
import 'package:touchable/touchable.dart';

class GameOfLifeBoard extends StatefulWidget {
  final int size;
  final void Function(List<List<bool>>) onChanged;
  final List<List<bool>> state;

  const GameOfLifeBoard({Key? key, required this.size, required this.onChanged, required this.state}) : super(key: key);

  @override
  _GameOfLifeBoardState createState() => _GameOfLifeBoardState();
}

class _GameOfLifeBoardState extends State<GameOfLifeBoard> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
            child: AspectRatio(
                aspectRatio: 1 / 1,
                child: CanvasTouchDetector(
                  gesturesToOverride: const [GestureType.onTapDown],
                  builder: (context) {
                    return CustomPaint(
                        painter: GameOfLifePainter(context, widget.size, widget.state, (int x, int y, bool value) {
                      setState(() {
                        widget.state[x][y] = value;
                        widget.onChanged(widget.state);
                      });
                    }));
                  },
                )))
      ],
    );
  }
}

class GameOfLifePainter extends CustomPainter {
  final int size;
  final List<List<bool>> state;
  final BuildContext context;
  final void Function(int, int, bool) onSetCell;

  GameOfLifePainter(this.context, this.size, this.state, this.onSetCell);

  @override
  void paint(Canvas canvas, Size size) {
    var _touchCanvas = TouchyCanvas(context, canvas);
    var paintLine = Paint();
    var paintFull = Paint();
    var paintBackground = Paint();
    var paintTransparent = Paint();
    double boxSize = size.width / this.size;

    paintLine.strokeWidth = (this.size > 20) ? 1 : 2;
    paintLine.style = PaintingStyle.stroke;
    paintLine.color = (this.size > 50) ? themeColors().secondary().withOpacity(0.0) : themeColors().secondary();

    paintBackground.style = PaintingStyle.fill;
    paintBackground.color = themeColors().gridBackground();

    paintTransparent.style = PaintingStyle.fill;
    paintTransparent.color = Colors.transparent;

    paintFull.style = PaintingStyle.fill;
    paintFull.color = themeColors().mainFont();


    _touchCanvas.drawRect(Rect.fromLTWH(0, 0, this.size  * boxSize, this.size * boxSize), paintBackground);

    for (int i = 0; i < this.size; i++) {
      for (int j = 0; j < this.size; j++) {

        var x = j * boxSize;
        var y = i * boxSize;

        var isSet = state[i][j] == true;

        _touchCanvas.drawRect(Rect.fromLTWH(x, y, boxSize, boxSize), isSet ? paintFull : paintTransparent,
            onTapDown: (tapDetail) {onSetCell(i, j, !isSet);});
      }
    }

    for (double i = 0; i <= this.size * boxSize + 0.0000001; i+=boxSize) {
      _touchCanvas.drawLine(Offset(i, 0.0), Offset(i, size.width), paintLine);
      _touchCanvas.drawLine(Offset(0.0, i), Offset(size.height, i), paintLine);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
