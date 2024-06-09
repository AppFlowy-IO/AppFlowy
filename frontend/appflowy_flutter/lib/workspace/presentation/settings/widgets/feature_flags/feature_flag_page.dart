import 'package:appflowy/shared/feature_flags.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class FeatureFlagsPage extends StatelessWidget {
  const FeatureFlagsPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsBody(
      title: 'Feature flags',
      children: [
        SeparatedColumn(
          children: FeatureFlag.data.entries
              .where((e) => e.key != FeatureFlag.unknown)
              .map((e) => _FeatureFlagItem(featureFlag: e.key))
              .toList(),
        ),
        FlowyTextButton(
          'Restart the app to apply changes',
          fontSize: 16.0,
          fontColor: Colors.red,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          onPressed: () async => runAppFlowy(),
        ),
      ],
    );
  }
}

class _FeatureFlagItem extends StatefulWidget {
  const _FeatureFlagItem({required this.featureFlag});

  final FeatureFlag featureFlag;

  @override
  State<_FeatureFlagItem> createState() => _FeatureFlagItemState();
}

class _FeatureFlagItemState extends State<_FeatureFlagItem> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: FlowyText(widget.featureFlag.name, fontSize: 16.0),
      subtitle: FlowyText.small(widget.featureFlag.description, maxLines: 3),
      trailing: Switch.adaptive(
        value: widget.featureFlag.isOn,
        onChanged: (value) =>
            setState(() async => widget.featureFlag.update(value)),
      ),
    );
  }
}
