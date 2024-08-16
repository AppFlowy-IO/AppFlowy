import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/widgets.dart';
import 'invite_members_screen.dart';

class WorkspaceSettingGroup extends StatelessWidget {
  const WorkspaceSettingGroup({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MobileSettingGroup(
      groupTitle: LocaleKeys.settings_appearance_members_label.tr(),
      settingItemList: [
        MobileSettingItem(
          name: LocaleKeys.settings_appearance_members_label.tr(),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(InviteMembersScreen.routeName);
          },
        ),
        MobileSettingItem(
          name: LocaleKeys.workspace_leaveCurrentWorkspace.tr(),
          onTap: () {},
        ),
      ],
    );
  }
}
