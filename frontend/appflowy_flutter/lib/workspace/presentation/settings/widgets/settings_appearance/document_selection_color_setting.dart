import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/document_color_setting_button.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/theme_setting_entry_template.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentSelectionColorSetting extends StatelessWidget {
  const DocumentSelectionColorSetting({
    super.key,
    required this.currentSelectionColor,
  });

  final Color currentSelectionColor;

  @override
  Widget build(BuildContext context) {
    const label = 'Document Selection Color';

    return ThemeSettingEntryTemplateWidget(
      label: label,
      resetButtonKey: const Key('DocumentSelectionColorResetButton'),
      onResetRequested: () =>
          context.read<AppearanceSettingsCubit>().resetDocumentSelectionColor(),
      trailing: [
        DocumentColorSettingButton(
          currentColor: currentSelectionColor,
          previewWidgetBuilder: (color) => _SelectionColorValueWidget(
            selectionColor: color ?? Colors.transparent,
          ),
          dialogTitle: label,
          onApply: (selectedColorOnDialog) => {
            context
                .read<AppearanceSettingsCubit>()
                .setDocumentSelectionColor(selectedColorOnDialog),
            // update the state of document appearance cubit with latest selection color
            context.read<DocumentAppearanceCubit>().fetch(),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: selectionColor,
          child: const FlowyText('App'),
        ),
        const FlowyText('flowy'),
      ],
    );
  }
}
