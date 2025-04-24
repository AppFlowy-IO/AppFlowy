import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_trailing.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
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
          trailing: MobileSettingTrailing(
            text: memberCount,
          ),
          onTap: () {
            context.push(InviteMembersScreen.routeName);
          },
        ),
      ],
    );
  }
}
