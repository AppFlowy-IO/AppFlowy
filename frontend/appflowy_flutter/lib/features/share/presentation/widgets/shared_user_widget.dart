import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/material.dart';

import '../../../share/data/models/share_role.dart';
import '../../../share/data/models/shared_user.dart';

/// Widget to display a single shared user row as per the UI design, using AFMenuItem.
class SharedUserWidget extends StatelessWidget {
  const SharedUserWidget({
    super.key,
    required this.user,
    this.isCurrentUser = false,
    this.onEdit,
  });
  final SharedUser user;
  final bool isCurrentUser;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final roleLabel = _roleLabel(user.role, isCurrentUser);
    final roleColor = _roleColor(user.role, theme);
    final name = user.name;
    final email = user.email;
    final subtitle = isCurrentUser ? '$email  (You)' : email;

    return AFMenuItem(
      leading: AFAvatar(
        name: name,
        url: user.avatarUrl,
        size: AFAvatarSize.l,
      ),
      title: name,
      subtitle: subtitle,
      trailing: isCurrentUser
          ? Text(
              'Full access',
              style: theme.textStyle.body
                  .standard(color: theme.textColorScheme.primary),
            )
          : AFGhostTextButton.primary(
              text: 'Edit',
              onTap: onEdit ?? () {},
              size: AFButtonSize.s,
            ),
      onTap: isCurrentUser ? () {} : onEdit ?? () {},
    );
  }

  String _roleLabel(ShareRole role, bool isCurrentUser) {
    if (isCurrentUser) return '';
    switch (role) {
      case ShareRole.readOnly:
        return 'Guest';
      case ShareRole.readAndComment:
        return 'Commenter';
      case ShareRole.readAndWrite:
        return 'Editor';
      case ShareRole.fullAccess:
        return 'Admin';
    }
  }

  Color _roleColor(ShareRole role, AppFlowyThemeData theme) {
    switch (role) {
      case ShareRole.readOnly:
        return theme.textColorScheme.warning;
      case ShareRole.readAndComment:
        return theme.textColorScheme.info;
      case ShareRole.readAndWrite:
        return theme.textColorScheme.success;
      case ShareRole.fullAccess:
        return theme.textColorScheme.primary;
    }
  }
}
