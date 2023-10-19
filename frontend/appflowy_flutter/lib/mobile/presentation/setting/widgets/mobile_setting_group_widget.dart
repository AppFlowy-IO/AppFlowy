import 'package:flutter/material.dart';

import 'mobile_setting_item_widget.dart';

class MobileSettingGroupWidget extends StatelessWidget {
  const MobileSettingGroupWidget({
    required this.groupTitle,
    required this.settingItemWidgets,
    this.showDivider = true,
    super.key,
  });
  final String groupTitle;
  final List<MobileSettingItemWidget> settingItemWidgets;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 8,
        ),
        Text(
          groupTitle,
          style: theme.textTheme.labelSmall,
        ),
        const SizedBox(
          height: 12,
        ),
        ...settingItemWidgets,
        showDivider ? const Divider() : const SizedBox.shrink(),
      ],
    );
  }
}
