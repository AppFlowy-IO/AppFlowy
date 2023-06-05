import 'package:appflowy/workspace/presentation/settings/widgets/settings_file_exporter_widget.dart';
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
  Widget build(final BuildContext context) {
    return ListTile(
      title: FlowyText.medium(
        LocaleKeys.settings_files_exportData.tr(),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: LocaleKeys.settings_files_open.tr(),
            child: FlowyIconButton(
              height: 40,
              width: 40,
              icon: const Icon(Icons.folder_open_outlined),
              hoverColor: Theme.of(context).colorScheme.secondaryContainer,
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (final context) {
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
          ),
        ],
      ),
    );
  }
}
