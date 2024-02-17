import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          FlowySvg(
            FlowySvgs.folder_m,
            size: ThemeUploadWidget.iconSize,
            color: Theme.of(context).colorScheme.onBackground,
          ),
          FlowyText.medium(
            LocaleKeys.settings_appearance_themeUpload_description.tr(),
            overflow: TextOverflow.ellipsis,
          ),
          ThemeUploadWidget.elementSpacer,
          const ThemeUploadLearnMoreButton(),
          ThemeUploadWidget.elementSpacer,
          const Divider(),
          ThemeUploadWidget.elementSpacer,
          const ThemeUploadButton(),
          ThemeUploadWidget.elementSpacer,
        ],
      ),
    );
  }
}
