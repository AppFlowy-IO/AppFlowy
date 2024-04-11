import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class MobileSettingItem extends StatelessWidget {
  const MobileSettingItem({
    super.key,
    required this.name,
    this.padding = const EdgeInsets.only(bottom: 4),
    this.trailing,
    this.leadingIcon,
    this.subtitle,
    this.onTap,
  });

  final String name;
  final EdgeInsets padding;
  final Widget? trailing;
  final Widget? leadingIcon;
  final Widget? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: ListTile(
        title: Row(
          children: [
            if (leadingIcon != null) ...[
              leadingIcon!,
              const HSpace(8),
            ],
            Expanded(
              child: FlowyText.medium(
                name,
                fontSize: 14.0,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: subtitle,
        trailing: trailing,
        onTap: onTap,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.only(left: 8.0),
      ),
    );
  }
}
