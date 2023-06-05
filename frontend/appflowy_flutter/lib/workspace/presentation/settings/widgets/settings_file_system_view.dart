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
  late final _items = [
    SettingsFileLocationCustomizer(
      cubit: _locationCubit,
    ),
    const SettingsExportFileWidget()
  ];

  @override
  Widget build(final BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemBuilder: (final context, final index) => _items[index],
      separatorBuilder: (final context, final index) => const Divider(),
      itemCount: _items.length,
    );
  }
}
