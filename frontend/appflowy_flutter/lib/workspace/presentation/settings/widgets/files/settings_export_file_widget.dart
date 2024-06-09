import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/files/settings_file_exporter_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:styled_widget/styled_widget.dart';

import '../../../../../generated/locale_keys.g.dart';

class SettingsExportFileWidget extends StatefulWidget {
  const SettingsExportFileWidget({super.key});

  @override
  State<SettingsExportFileWidget> createState() =>
      SettingsExportFileWidgetState();
}

@visibleForTesting
class SettingsExportFileWidgetState extends State<SettingsExportFileWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FlowyText.medium(
          LocaleKeys.settings_files_exportData.tr(),
          fontSize: 13,
          overflow: TextOverflow.ellipsis,
        ).padding(horizontal: 5.0),
        const Spacer(),
        _OpenExportedDirectoryButton(
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) {
                return const FlowyDialog(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: FileExporterWidget(),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _OpenExportedDirectoryButton extends StatelessWidget {
  const _OpenExportedDirectoryButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FlowyIconButton(
      hoverColor: Theme.of(context).colorScheme.secondaryContainer,
      tooltipText: LocaleKeys.settings_files_export.tr(),
      icon: FlowySvg(
        FlowySvgs.open_folder_lg,
        color: Theme.of(context).iconTheme.color,
      ),
      onPressed: onTap,
    );
  }
}
