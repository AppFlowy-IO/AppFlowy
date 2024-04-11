import 'package:appflowy/workspace/presentation/settings/widgets/files/setting_file_import_appflowy_data_view.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/files/settings_export_file_widget.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/files/settings_file_cache_widget.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/files/settings_file_customize_location_view.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class SettingsFileSystemView extends StatefulWidget {
  const SettingsFileSystemView({
    super.key,
  });

  @override
  State<SettingsFileSystemView> createState() => _SettingsFileSystemViewState();
}

class _SettingsFileSystemViewState extends State<SettingsFileSystemView> {
  late final _items = [
    const SettingsFileLocationCustomizer(),
    // disable export data for v0.2.0 in release mode.
    if (kDebugMode) const SettingsExportFileWidget(),
    const ImportAppFlowyData(),
    // clear the cache
    const SettingsFileCacheWidget(),
  ];

  @override
  Widget build(BuildContext context) {
    return SeparatedColumn(
      separatorBuilder: () => const Divider(),
      children: _items,
    );
  }
}
