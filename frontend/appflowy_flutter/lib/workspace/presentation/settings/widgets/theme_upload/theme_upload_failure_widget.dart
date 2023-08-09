import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';

import 'theme_upload_button.dart';
import 'theme_upload_view.dart';

class ThemeUploadFailureWidget extends StatelessWidget {
  const ThemeUploadFailureWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .error
          .withOpacity(ThemeUploadWidget.fadeOpacity),
      constraints: const BoxConstraints.expand(),
      padding: ThemeUploadWidget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FlowySvg(
            FlowySvgs.close_m,
            size: ThemeUploadWidget.iconSize,
            color: Theme.of(context).colorScheme.onBackground,
          ),
          FlowyText.medium(
            LocaleKeys.settings_appearance_themeUpload_failure.tr(),
            overflow: TextOverflow.ellipsis,
          ),
          ThemeUploadWidget.elementSpacer,
          ThemeUploadButton(color: Theme.of(context).colorScheme.error),
        ],
      ),
    );
  }
}
