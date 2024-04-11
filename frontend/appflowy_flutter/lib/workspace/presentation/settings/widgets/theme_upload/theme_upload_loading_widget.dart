import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class ThemeUploadLoadingWidget extends StatelessWidget {
  const ThemeUploadLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ThemeUploadWidget.padding,
      color: Theme.of(context)
          .colorScheme
          .background
          .withOpacity(ThemeUploadWidget.fadeOpacity),
      constraints: const BoxConstraints.expand(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          ThemeUploadWidget.elementSpacer,
          FlowyText.regular(
            LocaleKeys.settings_appearance_themeUpload_loading.tr(),
          ),
        ],
      ),
    );
  }
}
