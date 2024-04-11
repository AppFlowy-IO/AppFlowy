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

class DocumentSelectionColorSetting extends StatelessWidget {
  const DocumentSelectionColorSetting({
    super.key,
    required this.currentSelectionColor,
  });

  final Color currentSelectionColor;

  @override
  Widget build(BuildContext context) {
    final label =
        LocaleKeys.settings_appearance_documentSettings_selectionColor.tr();

    return FlowySettingListTile(
      label: label,
      resetButtonKey: const Key('DocumentSelectionColorResetButton'),
      onResetRequested: () {
        context.read<AppearanceSettingsCubit>().resetDocumentSelectionColor();
        context.read<DocumentAppearanceCubit>().syncSelectionColor(null);
      },
      trailing: [
        DocumentColorSettingButton(
          currentColor: currentSelectionColor,
          previewWidgetBuilder: (color) => _SelectionColorValueWidget(
            selectionColor: color ??
                DefaultAppearanceSettings.getDefaultDocumentSelectionColor(
                  context,
                ),
          ),
          dialogTitle: label,
          onApply: (selectedColorOnDialog) {
            context
                .read<AppearanceSettingsCubit>()
                .setDocumentSelectionColor(selectedColorOnDialog);
            // update the state of document appearance cubit with latest selection color
            context
                .read<DocumentAppearanceCubit>()
                .syncSelectionColor(selectedColorOnDialog);
          },
        ),
      ],
    );
  }
}

class _SelectionColorValueWidget extends StatelessWidget {
  const _SelectionColorValueWidget({
    required this.selectionColor,
  });

  final Color selectionColor;

  @override
  Widget build(BuildContext context) {
    // To avoid the text color changes when it is hovered in dark mode
    final textColor = Theme.of(context).colorScheme.onBackground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: selectionColor,
          child: FlowyText(
            LocaleKeys.settings_appearance_documentSettings_app.tr(),
            color: textColor,
          ),
        ),
        FlowyText(
          LocaleKeys.settings_appearance_documentSettings_flowy.tr(),
          color: textColor,
        ),
      ],
    );
  }
}
