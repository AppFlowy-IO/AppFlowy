import 'package:appflowy/features/share_tab/data/models/models.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/access_level_list_widget.dart';
import 'package:appflowy/features/share_tab/presentation/widgets/edit_access_level_widget.dart';
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
      ),
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
    final isCurrentUser = user.email == currentUser.email;

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
            LocaleKeys.shareTab_you.tr(),
            style: theme.textStyle.body.standard(
              color: theme.textColorScheme.secondary,
            ),
          ),
        ],
        // if the user is a guest, show 'Guest'
        if (user.role == ShareRole.guest) ...[
          HSpace(theme.spacing.xs),
          Text(
            LocaleKeys.shareTab_guest.tr(),
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
    final isCurrentUser = user.email == currentUser.email;
    final theme = AppFlowyTheme.of(context);
    // The current guest user can't edit the access level of the other user
    return isCurrentUser || currentUser.role == ShareRole.guest
        ? AFGhostTextButton.disabled(
            text: user.accessLevel.i18n,
            textStyle: theme.textStyle.body.standard(
              color: theme.textColorScheme.secondary,
            ),
          )
        : EditAccessLevelWidget(
            selectedAccessLevel: user.accessLevel,
            callbacks: callbacks ?? AccessLevelListCallbacks.none(),
          );
  }
}
