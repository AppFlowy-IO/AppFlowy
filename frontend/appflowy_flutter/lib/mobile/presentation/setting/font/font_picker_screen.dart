import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/widgets/flowy_mobile_search_text_field.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/util/google_font_family_extension.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

final List<String> _availableFonts = GoogleFonts.asMap().keys.toList();

class FontPickerScreen extends StatelessWidget {
  const FontPickerScreen({super.key});

  static const routeName = '/font_picker';

  @override
  Widget build(BuildContext context) {
    return const LanguagePickerPage();
  }
}

class LanguagePickerPage extends StatefulWidget {
  const LanguagePickerPage({super.key});

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
          child: ListView.builder(
            itemCount: availableFonts.length + 1, // with search bar
            itemBuilder: (context, index) {
              if (index == 0) {
                // search bar
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
                              (font) => font
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

              final fontFamilyName = availableFonts[index - 1];
              final displayName = fontFamilyName.parseFontFamilyName();
              return FlowyOptionTile.checkbox(
                text: displayName,
                isSelected: selectedFontFamilyName == fontFamilyName,
                showTopBorder: false,
                onTap: () => context.pop(fontFamilyName),
                fontFamily: GoogleFonts.getFont(fontFamilyName).fontFamily,
                backgroundColor: Colors.transparent,
              );
            },
          ),
        ),
      ),
    );
  }
}
