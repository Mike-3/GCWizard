import 'package:flutter/material.dart';
import 'package:gc_wizard/theme/colors.dart';
import 'package:gc_wizard/theme/theme.dart';
import 'package:gc_wizard/widgets/selector_lists/gcw_selection.dart';
import 'package:gc_wizard/widgets/utils/common_widget_utils.dart';
import 'package:prefs/prefs.dart';

enum ToolCategory {CRYPTOGRAPHY, COORDINATES, FORMULA_SOLVER, SCIENCE_AND_TECHNOLOGY, SYMBOL_TABLES}

class GCWToolWidget extends StatefulWidget {
  final Widget tool;
  final String i18nPrefix;
  final ToolCategory category;
  final autoScroll;
  final iconPath;
  final String searchStrings;
  final Map<String, dynamic> options;

  var icon;
  var _id = '';
  var _isFavorite = false;

  var toolName;
  var description;
  var example;

  GCWToolWidget({
    Key key,
    this.tool,
    this.toolName,
    this.i18nPrefix,
    this.category,
    this.autoScroll: true,
    this.iconPath,
    this.searchStrings: '',
    this.options
  }) : super(key: key) {
    this._id = className(tool) + '_' + (i18nPrefix ?? '');
    this._isFavorite = Prefs.getStringList('favorites').contains('$_id');

    if (iconPath != null) {
      this.icon = Container(
        child: Image.asset(iconPath, width: DEFAULT_LISTITEM_SIZE),
        padding: EdgeInsets.all(2),
        color: ThemeColors.symbolTableIconBackground,
      );
    }
  }

  bool get isFavorite {
    return this._isFavorite;
  }

  void set isFavorite(bool isFavorite) {
    _isFavorite = isFavorite;

    var _favorites = Prefs.getStringList('favorites');
    if (isFavorite && !_favorites.contains(_id)) {
      _favorites.add(_id);
    } else if (!isFavorite) {
      while (_favorites.contains(_id))
        _favorites.remove(_id);
    }
    Prefs.setStringList('favorites', _favorites);
  }

  @override
  _GCWToolWidgetState createState() => _GCWToolWidgetState();
}

class _GCWToolWidgetState extends State<GCWToolWidget> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.toolName),
      ),
      body: _buildBody()
    );
  }

  Widget _buildBody() {
    if (widget.tool is GCWSelection)
      return widget.tool;

    if (widget.autoScroll == false)
      return widget.tool;

    return SingleChildScrollView(
      child: Padding(
        child: widget.tool,
        padding: EdgeInsets.only(
          left: 10,
          right: 10
        ),
      )
    );
  }
}

