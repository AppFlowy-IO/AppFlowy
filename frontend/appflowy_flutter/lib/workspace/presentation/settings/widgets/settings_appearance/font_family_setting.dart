import 'dart:ui' as ui;

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'levenshtein.dart';
import 'theme_setting_entry_template.dart';

class ThemeFontFamilySetting extends StatefulWidget {
  const ThemeFontFamilySetting({
    super.key,
    required this.currentFontFamily,
  });

  final String currentFontFamily;
  static Key textFieldKey = const Key('FontFamilyTextField');
  static Key resetButtonkey = const Key('FontFamilyResetButton');
  static Key popoverKey = const Key('FontFamilyPopover');

  @override
  State<ThemeFontFamilySetting> createState() => _ThemeFontFamilySettingState();
}

class _ThemeFontFamilySettingState extends State<ThemeFontFamilySetting> {
  final List<String> availableFonts = GoogleFonts.asMap().keys.toList();
  final ValueNotifier<String> query = ValueNotifier('');

  @override
  Widget build(BuildContext context) {
    return ThemeSettingEntryTemplateWidget(
      label: LocaleKeys.settings_appearance_fontFamily_label.tr(),
      resetButtonKey: ThemeFontFamilySetting.resetButtonkey,
      onResetRequested: () {
        context.read<AppearanceSettingsCubit>().resetFontFamily();
        context
            .read<DocumentAppearanceCubit>()
            .syncFontFamily(DefaultAppearanceSettings.kDefaultFontFamily);
      },
      trailing: [
        ThemeValueDropDown(
          popoverKey: ThemeFontFamilySetting.popoverKey,
          currentValue: parseFontFamilyName(widget.currentFontFamily),
          onClose: () {
            query.value = '';
          },
          popupBuilder: (_) => CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(right: 8),
                sliver: SliverToBoxAdapter(
                  child: FlowyTextField(
                    key: ThemeFontFamilySetting.textFieldKey,
                    hintText:
                        LocaleKeys.settings_appearance_fontFamily_search.tr(),
                    autoFocus: false,
                    debounceDuration: const Duration(milliseconds: 300),
                    onChanged: (value) {
                      query.value = value;
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 4),
              ),
              ValueListenableBuilder(
                valueListenable: query,
                builder: (context, value, child) {
                  var displayed = availableFonts;
                  if (value.isNotEmpty) {
                    displayed = availableFonts
                        .where(
                          (font) => font
                              .toLowerCase()
                              .contains(value.toLowerCase().toString()),
                        )
                        .sorted((a, b) => levenshtein(a, b))
                        .toList();
                  }
                  return SliverFixedExtentList.builder(
                    itemBuilder: (context, index) => _fontFamilyItemButton(
                      context,
                      GoogleFonts.getFont(displayed[index]),
                    ),
                    itemCount: displayed.length,
                    itemExtent: 32,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  String parseFontFamilyName(String fontFamilyName) {
    final camelCase = RegExp('(?<=[a-z])[A-Z]');
    return fontFamilyName
        .replaceAll('_regular', '')
        .replaceAllMapped(camelCase, (m) => ' ${m.group(0)}');
  }

  bool _isTextOverflowing(String text, TextStyle textStyle, double maxWidth) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 1,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: maxWidth);

    return textPainter.didExceedMaxLines;
  }

  Widget _fontFamilyItemButton(BuildContext context, TextStyle style) {
    final buttonFontFamily = parseFontFamilyName(style.fontFamily!);

    final bool isOverFlown = _isTextOverflowing(
      buttonFontFamily,
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w500,
            fontFamily: buttonFontFamily,
          ),
      110,
    );

    return Tooltip(
      message: isOverFlown ? buttonFontFamily : "",
      margin: const EdgeInsets.only(right: 220),
      waitDuration: const Duration(milliseconds: 300),
      child: SizedBox(
        key: UniqueKey(),
        height: 32,
        child: FlowyButton(
          key: Key(buttonFontFamily),
          onHover: (_) => FocusScope.of(context).unfocus(),
          text: FlowyText.medium(
            parseFontFamilyName(style.fontFamily!),
            overflow: TextOverflow.ellipsis,
            fontFamily: style.fontFamily!,
          ),
          rightIcon:
              buttonFontFamily == parseFontFamilyName(widget.currentFontFamily)
                  ? const FlowySvg(
                      FlowySvgs.check_s,
                    )
                  : null,
          onTap: () {
            if (parseFontFamilyName(widget.currentFontFamily) !=
                buttonFontFamily) {
              context
                  .read<AppearanceSettingsCubit>()
                  .setFontFamily(parseFontFamilyName(style.fontFamily!));
              context
                  .read<DocumentAppearanceCubit>()
                  .syncFontFamily(parseFontFamilyName(style.fontFamily!));
            }
          },
        ),
      ),
    );
  }
}
