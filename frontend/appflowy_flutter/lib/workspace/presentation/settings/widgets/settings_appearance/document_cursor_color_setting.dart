import 'package:appflowy/plugins/document/presentation/more/cubit/document_appearance_cubit.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/document_color_setting_button.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_appearance/theme_setting_entry_template.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DocumentCursorColorSetting extends StatelessWidget {
  const DocumentCursorColorSetting({
    super.key,
    required this.currentCursorColor,
  });

  final Color currentCursorColor;

  @override
  Widget build(BuildContext context) {
    const label = 'Document Cursor Color';
    return ThemeSettingEntryTemplateWidget(
      label: label,
      onResetRequested: () =>
          context.read<AppearanceSettingsCubit>().resetDocumentCursorColor(),
      trailing: [
        DocumentColorSettingButton(
          key: const Key('DocumentCursorColorSettingButton'),
          currentColor: currentCursorColor,
          previewWidgetBuilder: (color) => _CursorColorValueWidget(
            cursorColor: color ?? Colors.transparent,
          ),
          dialogTitle: label,
          onApply: (selectedColorOnDialog) {
            context
                .read<AppearanceSettingsCubit>()
                .setDocumentCursorColor(selectedColorOnDialog);
            // update the state of document appearance cubit with latest cursor color
            context.read<DocumentAppearanceCubit>().fetch();
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
        const FlowyText('AppFlowy'),
      ],
    );
  }
}
