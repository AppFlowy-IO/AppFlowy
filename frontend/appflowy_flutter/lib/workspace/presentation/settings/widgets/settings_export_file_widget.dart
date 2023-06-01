import 'package:appflowy/workspace/presentation/settings/widgets/settings_file_exporter_widget.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';

import '../../../../generated/locale_keys.g.dart';

class SettingsExportFileWidget extends StatefulWidget {
  const SettingsExportFileWidget({
    super.key,
  });

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
          overflow: TextOverflow.ellipsis,
        ),
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
      tooltipText: LocaleKeys.settings_files_open.tr(),
      icon: svgWidget(
        'common/open_folder',
        color: Theme.of(context).iconTheme.color,
      ),
      onPressed: onTap,
    );
  }
}
