import 'package:appflowy/features/workspace/logic/workspace_bloc.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/setting/widgets/mobile_setting_trailing.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../widgets/widgets.dart';
import 'invite_members_screen.dart';

class WorkspaceSettingGroup extends StatelessWidget {
  const WorkspaceSettingGroup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
      builder: (context, state) {
        final currentWorkspace = state.workspaces.firstWhereOrNull(
          (e) => e.workspaceId == state.currentWorkspace?.workspaceId,
        );
        final memberCount = currentWorkspace?.memberCount;
        String memberCountText = '';
        // if the member count is greater than 0, show the member count
        if (memberCount != null && memberCount > 0) {
          memberCountText = memberCount.toString();
        }
        return MobileSettingGroup(
          groupTitle: LocaleKeys.settings_appearance_members_label.tr(),
          settingItemList: [
            MobileSettingItem(
              name: LocaleKeys.settings_appearance_members_label.tr(),
              trailing: MobileSettingTrailing(
                text: memberCountText,
              ),
              onTap: () {
                context.push(InviteMembersScreen.routeName);
              },
            ),
          ],
        );
      },
    );
  }
}
