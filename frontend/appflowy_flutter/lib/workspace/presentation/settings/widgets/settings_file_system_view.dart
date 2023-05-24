import 'package:appflowy/workspace/presentation/settings/widgets/settings_export_file_widget.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/settings_file_customize_location_view.dart';
import 'package:flutter/material.dart';

import '../../../application/settings/settings_location_cubit.dart';

class SettingsFileSystemView extends StatefulWidget {
  const SettingsFileSystemView({
    super.key,
  });

  @override
  State<SettingsFileSystemView> createState() => _SettingsFileSystemViewState();
}

class _SettingsFileSystemViewState extends State<SettingsFileSystemView> {
  final _locationCubit = SettingsLocationCubit()..fetchLocation();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemBuilder: (context, index) {
        if (index == 0) {
          return SettingsFileLocationCustomzier(
            cubit: _locationCubit,
          );
        } else if (index == 1) {
          return const SettingsExportFileWidget();
        }
        return const SizedBox.shrink();
      },
      separatorBuilder: (context, index) => const Divider(),
      itemCount: 2, // make the divider taking effect.
    );
  }
}
