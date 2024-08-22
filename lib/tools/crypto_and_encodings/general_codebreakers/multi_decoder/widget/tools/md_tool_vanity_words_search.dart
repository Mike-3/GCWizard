import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gc_wizard/application/i18n/logic/app_localizations.dart';
import 'package:gc_wizard/common_widgets/dropdowns/gcw_dropdown.dart';
import 'package:gc_wizard/tools/crypto_and_encodings/general_codebreakers/multi_decoder/widget/multi_decoder.dart';
import 'package:gc_wizard/tools/crypto_and_encodings/numeral_words/_common/logic/numeral_words.dart';
import 'package:gc_wizard/tools/science_and_technology/vanity/_common/logic/vanity_words.dart';
import 'package:gc_wizard/tools/science_and_technology/vanity/vanity_words_search/widget/vanity_words_search.dart';
import 'package:gc_wizard/utils/string_utils.dart';

const MDT_INTERNALNAMES_VANITYWORDSTEXTSEARCH = 'multidecoder_tool_vanitywordstextsearch_title';
const MDT_VANITYORDSTEXTSEARCH_OPTION_LANGUAGE = 'multidecoder_tool_vanitywordstextsearch_option_language';

class MultiDecoderToolVanityWordsTextSearch extends AbstractMultiDecoderTool {
  MultiDecoderToolVanityWordsTextSearch(
      {Key? key,
      required int id,
      required String name,
      required Map<String, Object?> options,
      required BuildContext context})
      : super(
            key: key,
            id: id,
            name: name,
            internalToolName: MDT_INTERNALNAMES_VANITYWORDSTEXTSEARCH,
            onDecode: (String input, String key) {
              var language = _parseStringToEnum(stringNullableTypeCheck(options[MDT_VANITYORDSTEXTSEARCH_OPTION_LANGUAGE], null));

              var detailedOutput = decodeVanityWords(removeAccents(input.toLowerCase()), language);

              var output = buildOutputString(detailedOutput, context);
              if (output.replaceAll(' ', '').replaceAll('.', '').isEmpty) return null;
              return output;
            },
            options: options);

  @override
  State<StatefulWidget> createState() => _MultiDecoderToolVanityMultitapState();
}

class _MultiDecoderToolVanityMultitapState extends State<MultiDecoderToolVanityWordsTextSearch> {
  @override
  Widget build(BuildContext context) {
    return createMultiDecoderToolConfiguration(context, {
      MDT_VANITYORDSTEXTSEARCH_OPTION_LANGUAGE: GCWDropDown<NumeralWordsLanguage>(
          value: _parseStringToEnum(checkStringFormatOrDefaultOption(
              MDT_INTERNALNAMES_VANITYWORDSTEXTSEARCH, widget.options, MDT_VANITYORDSTEXTSEARCH_OPTION_LANGUAGE)),
          onChanged: (newValue) {
            setState(() {
              widget.options[MDT_VANITYORDSTEXTSEARCH_OPTION_LANGUAGE] = numeralWordsLanguage(newValue);
            });
          },
          items: VANITYWORDS_LANGUAGES.entries.map((mode) {
            return GCWDropDownMenuItem(
              value: mode.key,
              child: i18n(context, mode.value),
            );
          }).toList(),
      )
    });
  }
}

NumeralWordsLanguage _parseStringToEnum(String? item) {
  var result = NumeralWordsLanguage.values.firstWhereOrNull((e) => numeralWordsLanguage(e) == item);
  if (result != null) return result;
  var value =
  _parseStringToEnum((getDefaultValue(MDT_INTERNALNAMES_VANITYWORDSTEXTSEARCH, MDT_VANITYORDSTEXTSEARCH_OPTION_LANGUAGE) ?? '').toString());
  return value;
}

String numeralWordsLanguage(NumeralWordsLanguage? item) {
  if (item == null) return '';
  return item
      .toString()
      .replaceAll('NumeralWordsLanguage.', '');
}
