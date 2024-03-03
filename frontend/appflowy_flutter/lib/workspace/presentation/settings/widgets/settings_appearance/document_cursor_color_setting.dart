import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_appearance_cubit.dart';
import 'package:appflowy/workspace/application/appearance_defaults.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/document_color_setting_button.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/theme_setting_entry_template.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentCursorColorSetting extends StatelessWidget {
  const DocumentCursorColorSetting({
    super.key,
    required this.currentCursorColor,
  });

  final Color currentCursorColor;

  @override
  Widget build(BuildContext context) {
    final label =
        LocaleKeys.settings_appearance_documentSettings_cursorColor.tr();
    return FlowySettingListTile(
      label: label,
      resetButtonKey: const Key('DocumentCursorColorResetButton'),
      onResetRequested: () {
        context.read<AppearanceSettingsCubit>().resetDocumentCursorColor();
        context.read<DocumentAppearanceCubit>().syncCursorColor(null);
      },
      trailing: [
        DocumentColorSettingButton(
          key: const Key('DocumentCursorColorSettingButton'),
          currentColor: currentCursorColor,
          previewWidgetBuilder: (color) => _CursorColorValueWidget(
            cursorColor: color ??
                DefaultAppearanceSettings.getDefaultDocumentCursorColor(
                  context,
                ),
          ),
          dialogTitle: label,
          onApply: (selectedColorOnDialog) {
            context
                .read<AppearanceSettingsCubit>()
                .setDocumentCursorColor(selectedColorOnDialog);
            // update the state of document appearance cubit with latest cursor color
            context
                .read<DocumentAppearanceCubit>()
                .syncCursorColor(selectedColorOnDialog);
          },
        ),
      ],
    );
  }
}

class _CursorColorValueWidget extends StatelessWidget {
  const _CursorColorValueWidget({
    required this.cursorColor,
  });

  final Color cursorColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: cursorColor,
          width: 2,
          height: 16,
        ),
        FlowyText(
          LocaleKeys.appName.tr(),
          // To avoid the text color changes when it is hovered in dark mode
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ],
    );
  }
}
