import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

class AFMenuItem extends StatelessWidget {
  const AFMenuItem({
    super.key,
    required this.title,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.selected = false,
    this.trailing,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return AFGhostButton.normal(
      onTap: onTap,
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.m,
        vertical: theme.spacing.s,
      ),
      borderRadius: theme.borderRadius.m,
      builder: (context, isHovering, disabled) => Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: theme.spacing.m),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textStyle.body.standard(
                    color: theme.textColorScheme.primary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: theme.textStyle.caption.standard(
                      color: theme.textColorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
