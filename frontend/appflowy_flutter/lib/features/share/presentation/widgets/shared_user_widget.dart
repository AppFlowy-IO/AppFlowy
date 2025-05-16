import 'package:appflowy/features/share/data/models/models.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

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
    return AFMenuItem(
      leading: AFAvatar(
        name: user.name,
        url: user.avatarUrl,
      ),
      title: _buildTitle(context),
      subtitle: _buildSubtitle(context),
      trailing: _buildTrailing(context),
    );
  }

  Widget _buildTitle(
    BuildContext context,
  ) {
    final theme = AppFlowyTheme.of(context);

    return Row(
      children: [
        Text(
          user.name,
          style: theme.textStyle.body.standard(
            color: theme.textColorScheme.primary,
          ),
        ),
        // if the user is the current user, show '(You)'
        if (isCurrentUser) ...[
          HSpace(theme.spacing.xs),
          Text(
            '(You)',
            style: theme.textStyle.body.standard(
              color: theme.textColorScheme.secondary,
            ),
          ),
        ],
        // if the user is a guest, show 'Guest'
        if (user.role == ShareRole.guest) ...[
          HSpace(theme.spacing.xs),
          Text(
            'Guest',
            style: theme.textStyle.body.standard(
              color: theme.textColorScheme.warning,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubtitle(
    BuildContext context,
  ) {
    final theme = AppFlowyTheme.of(context);
    return Text(
      user.email,
      style: theme.textStyle.caption.standard(
        color: theme.textColorScheme.secondary,
      ),
    );
  }

  Widget _buildTrailing(
    BuildContext context,
  ) {
    final theme = AppFlowyTheme.of(context);
    return isCurrentUser
        ? Text(
            'Full access',
            style: theme.textStyle.body
                .standard(color: theme.textColorScheme.secondary),
          )
        : AFGhostTextButton.primary(
            text: 'Edit',
            onTap: onEdit ?? () {},
            size: AFButtonSize.s,
          );
  }

  String _roleLabel(ShareAccessLevel role, bool isCurrentUser) {
    if (isCurrentUser) return '';
    switch (role) {
      case ShareAccessLevel.readOnly:
        return 'Guest';
      case ShareAccessLevel.readAndComment:
        return 'Commenter';
      case ShareAccessLevel.readAndWrite:
        return 'Editor';
      case ShareAccessLevel.fullAccess:
        return 'Admin';
    }
  }

  Color _roleColor(ShareAccessLevel role, AppFlowyThemeData theme) {
    switch (role) {
      case ShareAccessLevel.readOnly:
        return theme.textColorScheme.warning;
      case ShareAccessLevel.readAndComment:
        return theme.textColorScheme.info;
      case ShareAccessLevel.readAndWrite:
        return theme.textColorScheme.success;
      case ShareAccessLevel.fullAccess:
        return theme.textColorScheme.primary;
    }
  }
}
