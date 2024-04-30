import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar/app_bar.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LanguagePickerScreen extends StatelessWidget {
  const LanguagePickerScreen({super.key});

  static const routeName = '/language_picker';

  @override
  Widget build(BuildContext context) => const LanguagePickerPage();
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
    final supportedLocales = EasyLocalization.of(context)!.supportedLocales;
    return Scaffold(
      appBar: FlowyAppBar(
        titleText: LocaleKeys.titleBar_language.tr(),
      ),
      body: SafeArea(
        child: ListView.builder(
          itemBuilder: (context, index) {
            final locale = supportedLocales[index];
            return FlowyOptionTile.checkbox(
              text: languageFromLocale(locale),
              isSelected: EasyLocalization.of(context)!.locale == locale,
              showTopBorder: false,
              onTap: () => context.pop(locale),
              backgroundColor: Colors.transparent,
            );
          },
          itemCount: supportedLocales.length,
        ),
      ),
    );
  }
}
