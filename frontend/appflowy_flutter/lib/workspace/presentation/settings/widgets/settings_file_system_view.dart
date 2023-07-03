import 'package:appflowy/workspace/presentation/settings/widgets/settings_export_file_widget.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_file_customize_location_view.dart';
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
    if (kDebugMode) const SettingsExportFileWidget()
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemBuilder: (context, index) => _items[index],
      separatorBuilder: (context, index) => const Divider(),
      itemCount: _items.length,
    );
  }
}
