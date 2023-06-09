import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload_button.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

import 'theme_upload_view.dart';

class UploadNewThemeWidget extends StatelessWidget {
  const UploadNewThemeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .background
          .withOpacity(ThemeUploadWidget.fadeOpacity),
      padding: ThemeUploadWidget.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                svgWidget(
                  'folder',
                  size: ThemeUploadWidget.iconSize,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                FlowyText.medium(
                  LocaleKeys.settings_appearance_themeUpload_description.tr(),
                  overflow: TextOverflow.ellipsis,
                ),
                const Divider(),
                ThemeUploadWidget.elementSpacer,
                const ThemeUploadButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
