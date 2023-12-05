import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar_actions.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/plugins.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MobileCodeLanguagePickerScreen extends StatelessWidget {
  static const routeName = '/code_language_picker';

  const MobileCodeLanguagePickerScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
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
