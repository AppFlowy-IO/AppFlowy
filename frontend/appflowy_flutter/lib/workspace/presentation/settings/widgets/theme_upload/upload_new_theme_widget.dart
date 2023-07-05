import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/theme_upload/theme_upload_button.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme_upload_view.dart';

class UploadNewThemeWidget extends StatelessWidget {
  const UploadNewThemeWidget({super.key});

  static const learnMoreRedirect =
      'https://appflowy.gitbook.io/docs/essential-documentation/themes';

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context)
          .colorScheme
          .background
          .withOpacity(ThemeUploadWidget.fadeOpacity),
      padding: ThemeUploadWidget.padding,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
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
          ThemeUploadWidget.elementSpacer,
          SizedBox(
            height: ThemeUploadWidget.buttonSize.height,
            child: IntrinsicWidth(
              child: FlowyButton(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                hoverColor: Theme.of(context).colorScheme.onBackground,
                text: FlowyText.medium(
                  fontSize: ThemeUploadWidget.buttonFontSize,
                  color: Theme.of(context).colorScheme.onPrimary,
                  LocaleKeys.document_plugins_autoGeneratorLearnMore.tr(),
                ),
                onTap: () async {
                  final uri = Uri.parse(learnMoreRedirect);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  } else {
                    if (context.mounted) {
                      Dialogs.show(
                        context,
                        child: FlowyDialog(
                          child: FlowyErrorPage.message(
                            LocaleKeys
                                .settings_appearance_themeUpload_urlUploadFailure
                                .tr()
                                .replaceAll(
                                  '{}',
                                  uri.toString(),
                                ),
                            howToFix:
                                LocaleKeys.errorDialog_howToFixFallback.tr(),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
          const Divider(),
          ThemeUploadWidget.elementSpacer,
          const ThemeUploadButton(),
        ],
      ),
    );
  }
}
