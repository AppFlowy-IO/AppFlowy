import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_search_text_field.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/shared/google_fonts_extension.dart';
import 'package:appflowy/util/google_font_family_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/base_appearance.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

final List<String> _availableFonts = [
  builtInFontFamily(),
  ...GoogleFonts.asMap().keys,
];

class FontPickerScreen extends StatelessWidget {
  const FontPickerScreen({super.key});

  static const routeName = '/font_picker';

  @override
  Widget build(BuildContext context) {
    return const LanguagePickerPage();
  }
}

class LanguagePickerPage extends StatefulWidget {
  const LanguagePickerPage({
    super.key,
  });

  @override
  State<LanguagePickerPage> createState() => _LanguagePickerPageState();
}

class _LanguagePickerPageState extends State<LanguagePickerPage> {
  late List<String> availableFonts;

  @override
  void initState() {
    super.initState();

    availableFonts = _availableFonts;
  }

  @override
  Widget build(BuildContext context) {
    final selectedFontFamilyName =
        context.watch<AppearanceSettingsCubit>().state.font;
    return Scaffold(
      appBar: FlowyAppBar(
        titleText: LocaleKeys.titleBar_font.tr(),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: FontSelector(
            selectedFontFamilyName: selectedFontFamilyName,
            onFontFamilySelected: (fontFamilyName) =>
                context.pop(fontFamilyName),
          ),
        ),
      ),
    );
  }
}

class FontSelector extends StatefulWidget {
  const FontSelector({
    super.key,
    this.scrollController,
    required this.selectedFontFamilyName,
    required this.onFontFamilySelected,
  });

  final ScrollController? scrollController;
  final String selectedFontFamilyName;
  final void Function(String fontFamilyName) onFontFamilySelected;

  @override
  State<FontSelector> createState() => _FontSelectorState();
}

class _FontSelectorState extends State<FontSelector> {
  late List<String> availableFonts;

  @override
  void initState() {
    super.initState();

    availableFonts = _availableFonts;
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: availableFonts.length + 1, // with search bar
      itemBuilder: (context, index) {
        if (index == 0) {
          // search bar
          return _buildSearchBar(context);
        }

        final fontFamilyName = availableFonts[index - 1];
        final fontFamily = fontFamilyName != builtInFontFamily()
            ? getGoogleFontSafely(fontFamilyName).fontFamily
            : TextStyle(fontFamily: builtInFontFamily()).fontFamily;
        return FlowyOptionTile.checkbox(
          // display the default font name if the font family name is empty
          text: fontFamilyName.isNotEmpty
              ? fontFamilyName.parseFontFamilyName()
              : LocaleKeys.settings_appearance_fontFamily_defaultFont.tr(),
          isSelected: widget.selectedFontFamilyName == fontFamilyName,
          showTopBorder: false,
          onTap: () => widget.onFontFamilySelected(fontFamilyName),
          fontFamily: fontFamily,
          backgroundColor: Colors.transparent,
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 12.0,
      ),
      child: FlowyMobileSearchTextField(
        onChanged: (keyword) {
          setState(() {
            availableFonts = _availableFonts
                .where(
                  (font) =>
                      font.isEmpty || // keep the default one always
                      font
                          .parseFontFamilyName()
                          .toLowerCase()
                          .contains(keyword.toLowerCase()),
                )
                .toList();
          });
        },
      ),
    );
  }
}
