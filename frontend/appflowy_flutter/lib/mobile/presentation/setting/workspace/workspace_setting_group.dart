import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../widgets/widgets.dart';
import 'invite_members_screen.dart';

class WorkspaceSettingGroup extends StatelessWidget {
  const WorkspaceSettingGroup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final memberCount = context
            .read<UserWorkspaceBloc>()
            .state
            .currentWorkspace
            ?.memberCount
            .toString() ??
        '';
    return MobileSettingGroup(
      groupTitle: LocaleKeys.settings_appearance_members_label.tr(),
      settingItemList: [
        MobileSettingItem(
          name: LocaleKeys.settings_appearance_members_label.tr(),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                memberCount,
                style: theme.textStyle.heading4.standard(
                  color: theme.textColorScheme.secondary,
                ),
              ),
              const HSpace(8),
              FlowySvg(
                FlowySvgs.toolbar_arrow_right_m,
                size: Size.square(24),
                color: theme.iconColorScheme.tertiary,
              ),
            ],
          ),
          onTap: () {
            context.push(InviteMembersScreen.routeName);
          },
        ),
      ],
    );
  }
}
