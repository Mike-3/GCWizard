import 'package:flutter/material.dart';
import 'package:gc_wizard/common_widgets/dropdowns/gcw_dropdown.dart';
import 'package:gc_wizard/common_widgets/gcw_text.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_default_output.dart';
import 'package:gc_wizard/common_widgets/spinners/gcw_double_spinner.dart';
import 'package:gc_wizard/common_widgets/dividers/gcw_text_divider.dart';
import 'package:gc_wizard/tools/science_and_technology/unit_converter/widget/gcw_unit_dropdown.dart';
import 'package:gc_wizard/tools/science_and_technology/unit_converter/widget/gcw_unit_input.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/tools/science_and_technology/alcohol_mass/logic/alcohol_mass.dart';
import 'package:gc_wizard/tools/science_and_technology/unit_converter/logic/mass.dart';
import 'package:gc_wizard/tools/science_and_technology/unit_converter/logic/unit_category.dart';
import 'package:gc_wizard/tools/science_and_technology/unit_converter/logic/volume.dart';
import 'package:intl/intl.dart';

final _ALCOHOL_MASS = 'alcoholmass_alcoholmass';
final _VOLUME = 'alcoholmass_volume';
final _ALCOHOL_MASS_BY_VOLUME = 'alcoholmass_alcoholbyvolume';

class AlcoholMass extends StatefulWidget {
  @override
  AlcoholMassState createState() => AlcoholMassState();
}

class AlcoholMassState extends State<AlcoholMass> {
  final _MODES = [_ALCOHOL_MASS, _VOLUME, _ALCOHOL_MASS_BY_VOLUME];
  var _currentMode = _ALCOHOL_MASS;
  var _currentVolume = 0.0;
  var _currentPercent = 0.0;
  var _currentAlcoholMass = 0.0;

  Mass _currentOutputMass = MASS_GRAM;
  Volume _currentOutputVolume = VOLUME_MILLILITER;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GCWDropDown(
          value: _currentMode,
          items: _MODES.map((mode) {
            return GCWDropDownMenuItem(value: mode, child: i18n(context, mode));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _currentMode = value;
            });
          },
        ),
        _currentMode != _VOLUME
            ? GCWUnitInput(
                value: _currentVolume,
                title: i18n(context, _VOLUME),
                min: 0.0,
                unitCategory: UNITCATEGORY_VOLUME,
                initialUnit: VOLUME_MILLILITER,
                onChanged: (value) {
                  setState(() {
                    _currentVolume = value;
                  });
                },
              )
            : Container(), // Container Construct instead of simple "if" avoids some NULL Pointer issues, however... (when opening -> switching to VOLUME -> Crash because no Volume DropDown...)
        _currentMode != _ALCOHOL_MASS
            ? GCWUnitInput(
                value: _currentAlcoholMass,
                title: i18n(context, _ALCOHOL_MASS),
                min: 0.0,
                unitList: allMasses(),
                onChanged: (value) {
                  setState(() {
                    _currentAlcoholMass = value;
                  });
                },
              )
            : Container(),
        if (_currentMode != _ALCOHOL_MASS_BY_VOLUME)
          Row(
            children: [
              Expanded(
                  child: GCWText(
                    text: i18n(context, _ALCOHOL_MASS_BY_VOLUME),
                  ),
                  flex: 3),
              Expanded(
                  child: GCWDoubleSpinner(
                    value: _currentPercent,
                    onChanged: (value) {
                      setState(() {
                        _currentPercent = value;
                      });
                    },
                  ),
                  flex: 13)
            ],
          ),
        if (_currentMode != _ALCOHOL_MASS_BY_VOLUME) GCWTextDivider(text: i18n(context, 'common_outputunit')),
        _currentMode == _ALCOHOL_MASS
            ? GCWUnitDropDown(
                value: _currentOutputMass,
                unitList: allMasses(),
                onlyShowSymbols: false,
                onChanged: (value) {
                  setState(() {
                    _currentOutputMass = value;
                  });
                },
              )
            : Container(),
        _currentMode == _VOLUME
            ? GCWUnitDropDown(
                value: _currentOutputVolume,
                unitCategory: UNITCATEGORY_VOLUME,
                onlyShowSymbols: false,
                onChanged: (value) {
                  setState(() {
                    _currentOutputVolume = value;
                  });
                },
              )
            : Container(),
        _buildOutput()
      ],
    );
  }

  _buildOutput() {
    if (_currentMode == _ALCOHOL_MASS) {
      var mass = alcoholMassInG(VOLUME_MILLILITER.fromCubicMeter(_currentVolume), _currentPercent);
      var outputMass = _currentOutputMass.fromGram(mass);
      return GCWDefaultOutput(
        child: NumberFormat('0.000').format(outputMass) + ' ' + _currentOutputMass.symbol,
        copyText: outputMass,
      );
    }

    if (_currentMode == _VOLUME) {
      var volume = alcoholVolumeInML(_currentAlcoholMass, _currentPercent);
      var outputVolume = _currentOutputVolume.fromCubicMeter(VOLUME_MILLILITER.toCubicMeter(volume));
      return GCWDefaultOutput(
        child: NumberFormat('0.000').format(outputVolume) + ' ' + _currentOutputVolume.symbol,
        copyText: outputVolume,
      );
    }

    if (_currentMode == _ALCOHOL_MASS_BY_VOLUME) {
      var percent = alcoholByMassInPercent(_currentAlcoholMass, VOLUME_MILLILITER.fromCubicMeter(_currentVolume));
      return GCWDefaultOutput(
        child: NumberFormat('0.000').format(percent) + ' %',
        copyText: percent,
      );
    }
  }
}