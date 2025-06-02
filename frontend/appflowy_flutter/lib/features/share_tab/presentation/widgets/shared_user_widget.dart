import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/access_level_list_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/edit_access_level_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/guest_tag.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/turn_into_member_widget.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

/// Widget to display a single shared user row as per the UI design, using AFMenuItem.
class SharedUserWidget extends StatelessWidget {
  const SharedUserWidget({
    super.key,
    required this.user,
    required this.currentUser,
    this.callbacks,
  });

  final SharedUser user;
  final SharedUser currentUser;
  final AccessLevelListCallbacks? callbacks;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);

    return AFMenuItem(
      padding: EdgeInsets.symmetric(
        vertical: theme.spacing.s,
        horizontal: theme.spacing.m,
      ),
      leading: AFAvatar(
        name: user.name,
        url: user.avatarUrl,
      ),
      title: _buildTitle(context),
      subtitle: _buildSubtitle(context),
      trailing: _buildTrailing(context),
      onTap: () {
        // callbacks?.onSelectAccessLevel.call(user, user.accessLevel);
      },
    );
  }

  Widget _buildTitle(
    BuildContext context,
  ) {
    final theme = AppFlowyTheme.of(context);
    final isCurrentUser = user.email == currentUser.email;

    return Row(
      children: [
        Flexible(
          child: Text(
            user.name,
            style: theme.textStyle.body.standard(
              color: theme.textColorScheme.primary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // if the user is the current user, show '(You)'
        if (isCurrentUser) ...[
          HSpace(theme.spacing.xs),
          Text(
            LocaleKeys.shareTab_you.tr(),
            style: theme.textStyle.caption.standard(
              color: theme.textColorScheme.secondary,
            ),
          ),
        ],
        // if the user is a guest, show 'Guest'
        if (user.role == ShareRole.guest) ...[
          HSpace(theme.spacing.m),
          const GuestTag(),
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
    final isCurrentUser = user.email == currentUser.email;
    final theme = AppFlowyTheme.of(context);
    // Guest: read and write, read only
    // Member: full access <- only have full access until the backend supports more access levels
    // Owner: all access levels
    final supportedAccessLevels = switch (user.role) {
      ShareRole.guest => [
          ShareAccessLevel.readOnly,
          ShareAccessLevel.readAndWrite,
        ],
      ShareRole.member => [ShareAccessLevel.fullAccess],
      ShareRole.owner => [ShareAccessLevel.fullAccess],
    };

    Widget editAccessWidget;

    // The current guest user can't edit the access level of the other user
    if (isCurrentUser && currentUser.role == ShareRole.guest) {
      editAccessWidget = EditAccessLevelWidget(
        selectedAccessLevel: user.accessLevel,
        supportedAccessLevels: [],
        additionalUserManagementOptions: [
          AdditionalUserManagementOptions.removeAccess,
        ],
        callbacks: callbacks ?? AccessLevelListCallbacks.none(),
      );
    } else if (currentUser.role == ShareRole.guest ||
        user.role == ShareRole.member ||
        user.role == ShareRole.owner) {
      editAccessWidget = AFGhostTextButton.disabled(
        text: user.accessLevel.title,
        textStyle: theme.textStyle.body.standard(
          color: theme.textColorScheme.secondary,
        ),
      );
    } else {
      editAccessWidget = EditAccessLevelWidget(
        selectedAccessLevel: user.accessLevel,
        supportedAccessLevels: supportedAccessLevels,
        additionalUserManagementOptions: [
          AdditionalUserManagementOptions.removeAccess,
        ],
        callbacks: callbacks ?? AccessLevelListCallbacks.none(),
      );
    }

    if (user.role == ShareRole.guest) {
      return Row(
        children: [
          TurnIntoMemberWidget(
            onTap: () {
              callbacks?.onTurnIntoMember.call();
            },
          ),
          editAccessWidget,
        ],
      );
    }

    return editAccessWidget;
  }
}
