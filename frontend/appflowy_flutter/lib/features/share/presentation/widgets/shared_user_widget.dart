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

    return AFMenuItem(
      leading: AFAvatar(
        name: user.name,
        url: user.avatarUrl,
      ),
      title: _buildTitle(context, user: user),
      subtitle: _buildSubtitle(context, user: user),
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

  Widget _buildTitle(
    BuildContext context, {
    required SharedUser user,
  }) {
    final theme = AppFlowyTheme.of(context);
    // Text(
    //     title,
    //     style: theme.textStyle.body.standard(
    //       color: theme.textColorScheme.primary,
    //     ),
    //   ),
    //   subtitle: subtitle != null
    //       ? Text(
    //           subtitle!,
    //           style: theme.textStyle.caption.standard(
    //             color: theme.textColorScheme.secondary,
    //           ),
    //         )
    // if the user is a guest, adding a guest icon
    // if the user is the current user, adding a current user icon
    return Row(
      children: [
        Text(
          user.name,
          style: theme.textStyle.body.standard(
            color: theme.textColorScheme.primary,
          ),
        ),
        if (user.role == ShareRole.readOnly)
          Icon(
            Icons.person,
            color: theme.textColorScheme.primary,
          ),
        if (user.role == ShareRole.readAndComment)
          Icon(
            Icons.comment,
            color: theme.textColorScheme.primary,
          ),
        if (user.role == ShareRole.readAndWrite)
          Icon(
            Icons.edit,
            color: theme.textColorScheme.primary,
          ),
      ],
    );
  }

  Widget _buildSubtitle(
    BuildContext context, {
    required SharedUser user,
  }) {
    final theme = AppFlowyTheme.of(context);
    return Text(
      user.email,
      style: theme.textStyle.caption.standard(
        color: theme.textColorScheme.secondary,
      ),
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
