import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class SettingsCustomizeShortcuts extends StatelessWidget {
  const SettingsCustomizeShortcuts({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        FlowyText.medium(
          "Customize Shortcuts",
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
