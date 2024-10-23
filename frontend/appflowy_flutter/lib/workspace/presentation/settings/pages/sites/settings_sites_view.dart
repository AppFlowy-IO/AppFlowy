import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SettingsSitesPage extends StatefulWidget {
  const SettingsSitesPage({
    super.key,
  });

  @override
  State<SettingsSitesPage> createState() => _SettingsSitesPageState();
}

class _SettingsSitesPageState extends State<SettingsSitesPage> {
  // late final Future<>
  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      title: 'Sites',
      children: [
        SeparatedColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          separatorBuilder: () => const Divider(),
          children: const [],
        ),
      ],
    );
  }
}
