import 'package:flutter/material.dart';
import 'package:gc_wizard/theme/colors.dart';
import 'package:gc_wizard/widgets/utils/common_widget_utils.dart';

final FONT_SIZE_MIN = 10;
final FONT_SIZE_MAX = 30;

final DEFAULT_MARGIN = 2.0;

final DEFAULT_LISTITEM_SIZE = 42.0;
final DEFAULT_POPUPBUTTON_SIZE = 40.0;

TextStyle gcwTextStyle() {
 return TextStyle(
   fontSize: defaultFontSize(),
   fontFamily: 'Roboto Condensed'
 );
}

TextStyle gcwMonotypeTextStyle() {
  return TextStyle(
    fontSize: defaultFontSize(),
    fontFamily: 'Courier',
    fontWeight: FontWeight.bold
  );
}

TextStyle gcwHyperlinkTextStyle() {
  return TextStyle(
    color: ThemeColors.accent,
    decoration: TextDecoration.underline
  );
}

TextStyle gcwDescriptionTextStyle() {
  return TextStyle(
    fontSize: defaultFontSize() - 2,
    fontFamily: gcwTextStyle().fontFamily
  );
}

const roundedBorderRadius = 4.0;

ThemeData buildTheme() {
  final ThemeData base = ThemeData.dark();
  return ThemeData(
    scaffoldBackgroundColor: ThemeColors.primaryBackground,
    primaryColor: ThemeColors.primaryBackground,
    accentColor: ThemeColors.accent,
    textTheme: base.textTheme,
    buttonTheme: base.buttonTheme.copyWith(
      buttonColor: ThemeColors.accent,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(roundedBorderRadius)),
      )
    ),
    canvasColor: ThemeColors.inputBackground, //background of DropDownButton
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      hintStyle: TextStyle(color: ThemeColors.hintText),
      fillColor: ThemeColors.inputBackground,
      focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ThemeColors.focused, width: 2.0),
          borderRadius: BorderRadius.all(Radius.circular(roundedBorderRadius))
      ),
      enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: ThemeColors.accent, width: 1.0),
          borderRadius: BorderRadius.all(Radius.circular(roundedBorderRadius))
      ),
      contentPadding: EdgeInsets.all(10.0),
    ),
    unselectedWidgetColor: ThemeColors.accent
  );
}