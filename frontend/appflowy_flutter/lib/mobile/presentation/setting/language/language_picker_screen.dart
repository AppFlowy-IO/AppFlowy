import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/language.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LanguagePickerScreen extends StatelessWidget {
  static const routeName = '/language_picker';

  const LanguagePickerScreen({
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
    final supportedLocales = EasyLocalization.of(context)!.supportedLocales;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: FlowyText.semibold(
          LocaleKeys.titleBar_language.tr(),
          fontSize: 14.0,
        ),
        leading: const AppBarBackButton(),
      ),
      body: SafeArea(
        child: ListView.separated(
          itemBuilder: (context, index) {
            final locale = supportedLocales[index];
            return SizedBox(
              height: 48.0,
              child: InkWell(
                onTap: () => context.pop(locale),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      const HSpace(12.0),
                      FlowyText(
                        languageFromLocale(locale),
                      ),
                      const Spacer(),
                      if (EasyLocalization.of(context)!.locale == locale)
                        const Icon(
                          Icons.check,
                          size: 16,
                        ),
                      const HSpace(12.0),
                    ],
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(
            height: 1,
          ),
          itemCount: supportedLocales.length,
        ),
      ),
    );
  }
}
