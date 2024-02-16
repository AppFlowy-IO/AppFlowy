import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileCodeLanguagePickerScreen extends StatelessWidget {
  const MobileCodeLanguagePickerScreen({super.key});

  static const routeName = '/code_language_picker';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FlowyAppBar(
        titleText: LocaleKeys.titleBar_language.tr(),
      ),
      body: SafeArea(
        child: ListView.separated(
          itemBuilder: (context, index) {
            final language = codeBlockSupportedLanguages[index];
            return SizedBox(
              height: 48,
              child: FlowyTextButton(
                language.capitalize(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 4.0,
                ),
                onPressed: () => context.pop(language),
              ),
            );
          },
          separatorBuilder: (_, __) => const Divider(),
          itemCount: codeBlockSupportedLanguages.length,
        ),
      ),
    );
  }
}
