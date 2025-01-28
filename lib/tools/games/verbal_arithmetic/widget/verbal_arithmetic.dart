import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gc_wizard/application/i18n/logic/app_localizations.dart';
import 'package:gc_wizard/application/theme/theme.dart';
import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer.dart';
import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer_parameters.dart';
import 'package:gc_wizard/common_widgets/buttons/gcw_iconbutton.dart';
import 'package:gc_wizard/common_widgets/buttons/gcw_paste_button.dart';
import 'package:gc_wizard/common_widgets/buttons/gcw_submit_button.dart';
import 'package:gc_wizard/common_widgets/clipboard/gcw_clipboard.dart';
import 'package:gc_wizard/common_widgets/dropdowns/gcw_dropdown.dart';
import 'package:gc_wizard/common_widgets/gcw_expandable.dart';
import 'package:gc_wizard/common_widgets/gcw_painter_container.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_columned_multiline_output.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_default_output.dart';
import 'package:gc_wizard/common_widgets/spinners/gcw_integer_spinner.dart';
import 'package:gc_wizard/common_widgets/switches/gcw_onoff_switch.dart';
import 'package:gc_wizard/common_widgets/textfields/gcw_textfield.dart';
import 'package:gc_wizard/tools/games/verbal_arithmetic/logic/alphametic.dart';
import 'package:gc_wizard/tools/games/verbal_arithmetic/logic/cryptogram.dart';
import 'package:gc_wizard/tools/games/verbal_arithmetic/logic/helper.dart';

class VerbalArithmetic extends StatefulWidget {
  const VerbalArithmetic({Key? key}) : super(key: key);

  @override
  _VerbalArithmeticState createState() => _VerbalArithmeticState();
}

enum _ViewMode {
  Alphametic,
  SymbolMatrixTextBox,
  SymbolMatrixGrid
}

class _VerbalArithmeticState extends State<VerbalArithmetic> {
  late TextEditingController _inputNumberGridController;
  late TextEditingController _inputAlphameticsController;

  Widget? _currentOutput;
  var _currentNumberGridInput = '';
  var _currentAlphameticsInput = '';
  var _currentMode = _ViewMode.Alphametic;
  var _currentAllSolutions = false;
  var _currentAllowLeadingZeros = false;
  var _currentGridScale = 0.0;
  int _rowCount = 2;
  int _columnCount = 2;
  SymbolMatrixGrid _currentMatrix = SymbolMatrixGrid(2, 2);
  List<List<TextEditingController?>> _textEditingControllerArray = [];
  bool _currentExpanded = false;

  @override
  void initState() {
    super.initState();

    _inputNumberGridController = TextEditingController(text: _currentNumberGridInput);
    _inputAlphameticsController = TextEditingController(text: _currentAlphameticsInput);

    _resizeMatrix();
  }

  @override
  void dispose() {
    _inputNumberGridController.dispose();
    _inputAlphameticsController.dispose();

    for(var y = 0; y < _textEditingControllerArray.length; y++) {
      for (var x = 0; x < _textEditingControllerArray[y].length; x++) {
        _textEditingControllerArray[y][x]?.dispose();
      }
    }
    _textEditingControllerArray.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGridScale <= 0) {
      _currentGridScale = max(1, (_tableMinWidth() / maxScreenWidth(context)));
    }

    return Column(
      children: <Widget>[
        GCWDropDown<_ViewMode>(
        value: _currentMode,
          items: [
            GCWDropDownMenuItem(
              value: _ViewMode.Alphametic,
              child: 'Alphametic',
              subtitle: 'SEND + MORE = MONEY'
            ),
            GCWDropDownMenuItem(
              value: _ViewMode.SymbolMatrixTextBox,
              child: 'SymbolMatrix TextBox',
              subtitle: 'A * B = 1428\nC - D = 12\nA * C = 840\nB - D = 33',
              maxSubtitleLines: 4
            ),
            GCWDropDownMenuItem(
              value: _ViewMode.SymbolMatrixGrid,
              child: 'SymbolMatrix Grid',
              subtitle: ' A * B = 1428\n  *    -\n C  - D = 12\n =    =\n840 33',
                maxSubtitleLines: 5
            )
          ],
          onChanged: (value) {
            setState(() {
              _currentMode = value;
            });
          }
        ),
        _buildOptionWidget(),
        _buildInput(),
        _buildSubmitButton(),
        _buildOutput()
      ]);
  }

  Widget _buildInput() {
    switch (_currentMode) {
      case _ViewMode.Alphametic:
        return _buildAlphameticsInput();
      case _ViewMode.SymbolMatrixTextBox:
        return _buildNumberGridTextboxInput();
      case _ViewMode.SymbolMatrixGrid:
        return _buildNumberGridGridInput();
    }
  }

  Widget _buildAlphameticsInput() {
    return Column(
      children: <Widget>[
        GCWTextField(
          hintText: 'SEND + MORE = MONEY',
          controller: _inputAlphameticsController,
          onChanged: (text) {
            setState(() {
              _currentAlphameticsInput = text;
            });
          }
        ),
      ],
    );
  }


  Widget _buildNumberGridTextboxInput() {
    return Column(
      children: <Widget>[
        GCWTextField(
          hintText: 'A * B = 1428\nC - D = 12\nA * C = 840\nB - D = 33',
          controller: _inputNumberGridController,
          onChanged: (text) {
            setState(() {
              _currentNumberGridInput = text;
            });
          }
        )
      ],
    );
  }

  Widget _buildOptionWidget() {
    return Column(
      children: <Widget>[
        GCWExpandableTextDivider(
          text: i18n(context, 'common_options'),
          expanded: _currentExpanded,
          onChanged: (value) {
            setState(() {
              _currentExpanded = value;
            });
          },
          child: Column(
            children: <Widget>[
              GCWOnOffSwitch(
                title: 'All solutions', //i18n(context, 'dates_daycalculator_countstart'),
                value: _currentAllSolutions,
                onChanged: (value) {
                  setState(() {
                    _currentAllSolutions = value;
                  });
                },
              ),
              _buildAllowLeadingZerosOption(),
              _buildNumberGridGridOption(),
              Container(height: 10)
            ]),
          )
      ]);
  }

  Widget _buildAllowLeadingZerosOption() {
    if (_currentMode == _ViewMode.SymbolMatrixTextBox || _currentMode == _ViewMode.SymbolMatrixGrid) {
      return Container();
    }
    return GCWOnOffSwitch(
      title: 'Allow Leading Zeros', //i18n(context, 'dates_daycalculator_countstart'),
      value: _currentAllowLeadingZeros,
      onChanged: (value) {
        setState(() {
          _currentAllowLeadingZeros = value;
        });
      },
    );
  }

  Widget _buildNumberGridGridOption() {
    if (_currentMode != _ViewMode.SymbolMatrixGrid) {
      return Container();
    }
    return Column(
      children: <Widget>[
        GCWIntegerSpinner(
          title: i18n(context, 'common_row_count'),
          value: _rowCount,
          min: 1,
          max: 20,
          onChanged: (value) {
            setState(() {
              _rowCount = value;
              _resizeMatrix();
            });
          },
        ),
        GCWIntegerSpinner(
          title: i18n(context, 'common_column_count'),
          value: _columnCount,
          min: 1,
          max: 20,
          onChanged: (value) {
            setState(() {
              _columnCount = value;
              _resizeMatrix();
            });
          },
        ),
      ]);
  }

  Widget _buildNumberGridGridInput() {
    return Column(
      children: <Widget>[
        GCWPainterContainer(
          scale: _currentGridScale,
          onChanged: (scale) {
            _currentGridScale = scale;
          },
          trailing: Row(children: <Widget>[
            GCWPasteButton(
              iconSize: IconButtonSize.SMALL,
              onSelected: _parseClipboard,
            ),
            GCWIconButton(
              size: IconButtonSize.SMALL,
              icon: Icons.content_copy,
              onPressed: () {
                var copyText = _currentMatrix.toJson();
                if (copyText.isEmpty) return;
                insertIntoGCWClipboard(context, copyText);
              }
            ),
            Container(width: 10)
          ]),
          child: _buildTable(_rowCount, _columnCount),
        ),
      ],
    );
  }

  Widget _buildOutput() {
    return _currentOutput ?? const GCWDefaultOutput(child: '');
  }

  void _onDoCalculation() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: SizedBox(
            height: GCW_ASYNC_EXECUTER_INDICATOR_HEIGHT,
            width: GCW_ASYNC_EXECUTER_INDICATOR_WIDTH,
            child: asyncExecuter(),
          ),
        );
      },
    );
  }

  GCWAsyncExecuter<VerbalArithmeticOutput?> asyncExecuter() {
    switch (_currentMode) {
      case _ViewMode.Alphametic:
        return GCWAsyncExecuter<VerbalArithmeticOutput?>(
          isolatedFunction: solveAlphameticsAsync,
          parameter: _buildJobData,
          onReady: (data) => _showOutput(data),
          isOverlay: true,
          );
      case _ViewMode.SymbolMatrixTextBox:
      case _ViewMode.SymbolMatrixGrid:
        return GCWAsyncExecuter<VerbalArithmeticOutput?>(
          isolatedFunction: solveCryptogramAsync,
          parameter: _buildJobData,
          onReady: (data) => _showOutput(data),
          isOverlay: true,
        );
    }
  }

  Widget _buildSubmitButton() {
    return GCWSubmitButton(
      onPressed: () async {
        _onDoCalculation();
      },
    );
  }

  void _parseClipboard(String text) {
    setState(() {
      var matrix = SymbolMatrixGrid.fromJson(text);
      if (matrix == null) {
        _rowCount = 2;
        _columnCount = 2;
        _currentMatrix = SymbolMatrixGrid(_rowCount, _columnCount);
      } else {
        _currentMatrix = matrix;
        _rowCount = matrix.rowCount;
        _columnCount = matrix.columnCount;
      }
      _resizeMatrix();
    });
  }

  Widget _buildTable(int rowCount, int columnCount) {
    var rows = <TableRow>[];
    for (var i = 0; i < _currentMatrix.getRowsCount(); i++) {
      rows.add(_buildTableRow(rowCount, columnCount, i));
    }

    return Table(
        border: const TableBorder.symmetric(outside: BorderSide(width: _BORDERWIDTH, color: Colors.transparent)),
        columnWidths: _columnWidthConfiguration(columnCount),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: rows
    );
  }

  TableRow _buildTableRow(int rowCount, int columnCount, int rowIndex) {
    var cells = <Widget>[];
    var rowsCount = _currentMatrix.getRowsCount() - 1;
    var columnsCount = _currentMatrix.getColumnsCount() - 1;


    for(var columnIndex = 0; columnIndex <= columnsCount; columnIndex++) {
      if (rowIndex % 2 == 0) {
        if (columnIndex % 2 == 0 && !( columnIndex == columnsCount && rowIndex == rowsCount)) {
          cells.add(
            GCWTextField(
              controller: _getTextEditingController(rowIndex, columnIndex,
                  _currentMatrix.getValue(rowIndex, columnIndex) ?? ''),
              onChanged: (text) {
                _currentMatrix.setValue(rowIndex, columnIndex, text);
              }
            )
          );
        } else if (columnIndex == columnsCount - 1 && rowIndex != rowsCount) {
          cells.add(_equalText(rowIndex, columnIndex));
        } else {
          cells.add(
            (rowIndex == rowsCount)
            ? Container() // last row
            : _operatorDropDown(rowIndex, columnIndex)
          );
        }
      } else if (columnIndex % 2 == 0 && columnIndex < columnsCount - 1) {
        cells.add(
          (rowIndex == _currentMatrix.getRowsCount() - 2)
          ? _equalText(rowIndex, columnIndex) // pre last row
          : _operatorDropDown(rowIndex, columnIndex)
        );
      } else {
        cells.add(Container());
      }
    }

    return TableRow(
      children: cells,
    );
  }

  static const double _VALUECOLUMNWIDTH = 20.0;
  static const double _OPERATORCOLUMNWIDTH = 55.0;
  static const double _EQUALSIGNWIDTH = 30.0;
  static const double _BORDERWIDTH = 5.0;

  Map<int, TableColumnWidth> _columnWidthConfiguration(int columnCount) {
    var config = <int, TableColumnWidth>{};
    var columsCount = _currentMatrix.getColumnsCount();
    for(var columnIndex = 0; columnIndex < columsCount; columnIndex++) {
      if (columnIndex % 2 == 0) {
        config.addAll({columnIndex:  const FlexColumnWidth()});
      } else {
        config.addAll({columnIndex: FixedColumnWidth((columnIndex == columsCount - 2)
            ? _EQUALSIGNWIDTH
            : _OPERATORCOLUMNWIDTH)});
      }
    }
    return config;
  }

  double _tableMinWidth() {
    var count = _currentMatrix.getColumnsCount();
    return (count + 1) * _VALUECOLUMNWIDTH + (count - 1) * _OPERATORCOLUMNWIDTH
        + _EQUALSIGNWIDTH + 2 * _BORDERWIDTH;
  }

  Widget _equalText(int rowIndex, int columnIndex) {
    _currentMatrix.setValue(rowIndex, columnIndex, '=');
    return Text('=',
      style: gcwTextStyle(),
      textAlign: TextAlign.center,
    );
  }

  Widget _operatorDropDown(int rowIndex, int columnIndex) {
    var list = <GCWDropDownMenuItem<String>>[];

    operatorList.forEach((key, value) {
      list.add(GCWDropDownMenuItem(
        value: key,
        child: key,
      ));
    });

    return GCWDropDown<String?>(
        value: _currentMatrix.getOperator(rowIndex, columnIndex),
        items: list,
        onChanged: (newValue) {
          setState(() {
            _currentMatrix.setValue(rowIndex, columnIndex, newValue ?? '');
          });
        }
    );
  }

  void _resizeMatrix() {
    _currentMatrix = SymbolMatrixGrid(_rowCount, _columnCount, oldMatrix: _currentMatrix);
    _buildTextEditingControllerArray(_rowCount, _columnCount);
  }

  Future<GCWAsyncExecuterParameters?> _buildJobData() async {
    List<String> _equations;
    switch (_currentMode) {
      case _ViewMode.Alphametic:
        if (_currentAlphameticsInput.isEmpty) return null;
        _equations = [_currentAlphameticsInput];
        break;
      case _ViewMode.SymbolMatrixTextBox:
        _equations = SymbolMatrixString.buildEquations(_currentNumberGridInput);
      case _ViewMode.SymbolMatrixGrid:
        _equations = _currentMatrix.buildEquations();
        break;
    }
    if (_equations.isEmpty) return null;

    return GCWAsyncExecuterParameters(VerbalArithmeticJobData(
        equations: _equations,
        substitutions: {},
        allSolutions: _currentAllSolutions,
        allowLeadingZeros: _currentAllowLeadingZeros
    ));
  }

  void _showOutput(VerbalArithmeticOutput? output) {
    if (output == null) {
      _currentOutput = null; //invalid data
      return;
    }
    if (output.error.isNotEmpty) {
      _currentOutput = GCWDefaultOutput(child:
        i18n(context, 'verbal_arithmetic_' + output.error.toLowerCase(), ifTranslationNotExists: output.error));
    } else if (output.solutions.isEmpty) {
      _currentOutput =  GCWDefaultOutput(child: i18n(context, 'verbal_arithmetic_solutionnotfound'));
    } else {
      Widget solutionWidget = Container();
      if (output.solutions.length == 1) {
        var solution = output.solutions.first.entries.toList();
        solution.sort(((a, b) => a.key.compareTo(b.key)));
        var _columnData = solution.map((entry) => [entry.key, entry.value]).toList();
        solutionWidget = GCWColumnedMultilineOutput(data: _columnData, flexValues: const [3, 1],
            copyColumn: 1, copyAll: true);
      }
      var equations = output.solutions.map((solution) {
        return output.equations.map((equation) => equation.getOutput(solution)).join('\n');
      }).join('\n\n');

      _currentOutput = Column(
          children: <Widget>[
            solutionWidget,
            GCWDefaultOutput(child: equations),
          ]
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  void _buildTextEditingControllerArray(int rowCount, int columnCount) {
    var matrix =<List<TextEditingController?>>[];
    for(var y = 0; y < _currentMatrix.getRowsCount(); y++) {
      matrix.add(List<TextEditingController?>.filled(_currentMatrix.getColumnsCount(), null));
    }

    for(var y = 0; y < min(matrix.length, _textEditingControllerArray.length); y++) {
      for (var x = 0; x < min(matrix[y].length, _textEditingControllerArray[y].length); x++) {
        matrix[y][x] = _textEditingControllerArray[y][x];
      }

      for(var y = matrix.length; y < _textEditingControllerArray.length; y++) {
        for (var x = matrix[0].length; x < _textEditingControllerArray[y].length; x++) {
          _textEditingControllerArray[y][x]?.dispose();
        }
      }
    }
    _textEditingControllerArray = matrix;
  }

  TextEditingController? _getTextEditingController(int rowIndex, int columnIndex, String text) {
    if (_textEditingControllerArray[rowIndex][columnIndex] == null) {
      _textEditingControllerArray[rowIndex][columnIndex] = TextEditingController();
    }
    _textEditingControllerArray[rowIndex][columnIndex]!.text = text;

    return _textEditingControllerArray[rowIndex][columnIndex];
  }
}