import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileSettingGroup extends StatelessWidget {
  const MobileSettingGroup({
    required this.groupTitle,
    required this.settingItemList,
    this.showDivider = true,
    super.key,
  });

  final String groupTitle;
  final List<Widget> settingItemList;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VSpace(4.0),
        FlowyText.semibold(
          groupTitle,
        ),
        const VSpace(4.0),
        ...settingItemList,
        showDivider ? const Divider() : const SizedBox.shrink(),
      ],
    );
  }
}
