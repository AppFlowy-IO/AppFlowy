import 'package:appflowy/workspace/presentation/settings/widgets/settings_file_customize_location_view.dart';
import 'package:flutter/material.dart';

class SettingsFileSystemView extends StatefulWidget {
  const SettingsFileSystemView({
    super.key,
  });

  @override
  State<SettingsFileSystemView> createState() => _SettingsFileSystemViewState();
}

class _SettingsFileSystemViewState extends State<SettingsFileSystemView> {
  @override
  Widget build(BuildContext context) {
    // return Column(
    //   children: [],
    // );
    return ListView.separated(
      itemBuilder: (context, index) {
        if (index == 0) {
          return const SettingsFileLocationCustomizer();
        } else if (index == 1) {
          // return _buildExportDatabaseButton();
        }
        return Container();
      },
      separatorBuilder: (context, index) => const Divider(),
      itemCount: 2, // make the divider taking effect.
    );
  }
}
