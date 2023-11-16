import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

final List<String> _availableFonts = GoogleFonts.asMap().keys.toList();

class FontPickerScreen extends StatelessWidget {
  static const routeName = '/font_picker';

  const FontPickerScreen({
    super.key,
  });

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
  @override
  Widget build(BuildContext context) {
    final selectedFontFamilyName =
        context.watch<AppearanceSettingsCubit>().state.font;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: FlowyText.semibold(
          LocaleKeys.titleBar_font.tr(),
          fontSize: 14.0,
        ),
        leading: AppBarBackButton(
          onTap: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          itemBuilder: (context, index) {
            final fontFamilyName = _availableFonts[index];
            final displayName = parseFontFamilyName(fontFamilyName);
            return InkWell(
              onTap: () => context.pop(fontFamilyName),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 12.0,
                ),
                child: Row(
                  children: [
                    const HSpace(12.0),
                    FlowyText(
                      displayName,
                      fontFamily:
                          GoogleFonts.getFont(fontFamilyName).fontFamily,
                    ),
                    const Spacer(),
                    if (selectedFontFamilyName == fontFamilyName)
                      const Icon(
                        Icons.check,
                        size: 16,
                      ),
                    const HSpace(12.0),
                  ],
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(
            height: 1,
          ),
          itemCount: _availableFonts.length,
        ),
      ),
    );
  }

  String parseFontFamilyName(String fontFamilyName) {
    final camelCase = RegExp('(?<=[a-z])[A-Z]');
    return fontFamilyName
        .replaceAll('_regular', '')
        .replaceAllMapped(camelCase, (m) => ' ${m.group(0)}');
  }
}
