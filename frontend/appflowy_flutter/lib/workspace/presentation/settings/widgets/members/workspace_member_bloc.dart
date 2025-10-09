import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/copy_and_paste/clipboard_service.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/invitation/invite_member_by_email.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/invitation/invite_member_by_link.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy/workspace/presentation/widgets/user_avatar.dart';
import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class WorkspaceMembersPage extends StatelessWidget {
  final UserProfilePB userProfile;
  final String workspaceId;

  const WorkspaceMembersPage({
    super.key,
    required this.userProfile,
    required this.workspaceId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkspaceMemberBloc>(
      create: (_) => WorkspaceMemberBloc(userProfile: userProfile, workspaceId: workspaceId)
        ..add(const WorkspaceMemberEvent.initial())
        ..add(const WorkspaceMemberEvent.getInviteCode()),
      child: Scaffold(
        appBar: AppBar(title: Text(LocaleKeys.settings_appearance_members_title.tr())),
        body: BlocConsumer<WorkspaceMemberBloc, WorkspaceMemberState>(
          listener: (context, state) => _handleActionResult(context, state),
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SettingsBody(
              title: LocaleKeys.settings_appearance_members_title.tr(),
              autoSeparate: false,
              children: [
                // Invite sections shown only if user can invite
                if (state.myRole.canInvite) ...[
                  const InviteMemberByLink(),
                  const SettingsCategorySpacer(),
                  const InviteMemberByEmail(),
                  const SettingsCategorySpacer(bottomSpacing: 0),
                ],
                if (state.members.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        LocaleKeys.settings_appearance_members_noMembers.tr(),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  )
                else
                  _MemberList(
                    members: state.members,
                    myRole: state.myRole,
                    userProfile: userProfile,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleActionResult(BuildContext context, WorkspaceMemberState state) {
    final actionResult = state.actionResult;
    if (actionResult == null) return;

    final result = actionResult.result;
    final type = actionResult.actionType;

    switch (type) {
      case WorkspaceMemberActionType.addByEmail:
        result.fold(
          (_) => showToastNotification(message: LocaleKeys.settings_appearance_members_addMemberSuccess.tr()),
          (fail) => _showErrorDialog(context, fail.code),
        );
        break;

      case WorkspaceMemberActionType.inviteByEmail:
        result.fold(
          (_) => showToastNotification(message: LocaleKeys.settings_appearance_members_inviteMemberSuccess.tr()),
          (fail) => showConfirmDialog(
            context: context,
            title: LocaleKeys.settings_appearance_members_inviteFailedDialogTitle.tr(),
            description: fail.code == ErrorCode.WorkspaceMemberLimitExceeded
                ? LocaleKeys.settings_appearance_members_inviteFailedMemberLimit.tr()
                : LocaleKeys.settings_appearance_members_failedToInviteMember.tr(),
            confirmLabel: LocaleKeys.settings_appearance_members_memberLimitExceededUpgrade.tr(),
            onConfirm: (_) => context.read<WorkspaceMemberBloc>().add(const WorkspaceMemberEvent.upgradePlan()),
          ),
        );
        break;

      case WorkspaceMemberActionType.generateInviteLink:
      case WorkspaceMemberActionType.resetInviteLink:
        result.fold(
          (_) async {
            showToastNotification(
              message: type == WorkspaceMemberActionType.generateInviteLink
                  ? LocaleKeys.settings_appearance_members_generatedLinkSuccessfully.tr()
                  : LocaleKeys.settings_appearance_members_resetLinkSuccessfully.tr(),
            );
            final inviteLink = state.inviteLink;
            if (inviteLink != null) {
              await getIt<ClipboardService>().setPlainText(inviteLink);
              Future.delayed(const Duration(milliseconds: 200), () {
                showToastNotification(message: LocaleKeys.shareAction_copyLinkSuccess.tr());
              });
            }
          },
          (fail) => showToastNotification(
            type: ToastificationType.error,
            message: type == WorkspaceMemberActionType.generateInviteLink
                ? LocaleKeys.settings_appearance_members_generatedLinkFailed.tr()
                : LocaleKeys.settings_appearance_members_resetLinkFailed.tr(),
          ),
        );
        break;

      default:
        break;
    }
  }

  void _showErrorDialog(BuildContext context, ErrorCode code) {
    final msg = code == ErrorCode.WorkspaceMemberLimitExceeded
        ? LocaleKeys.settings_appearance_members_memberLimitExceeded.tr()
        : LocaleKeys.settings_appearance_members_failedToAddMember.tr();
    showDialog(
      context: context,
      builder: (_) => NavigatorOkCancelDialog(message: msg),
    );
  }
}

class _MemberList extends StatelessWidget {
  final List<WorkspaceMemberPB> members;
  final AFRolePB myRole;
  final UserProfilePB userProfile;

  const _MemberList({
    required this.members,
    required this.myRole,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: members.length + 1,
      separatorBuilder: (_, __) => Divider(color: theme.borderColorScheme.primary),
      itemBuilder: (context, index) {
        if (index == 0) return const _MemberListHeader();
        final member = members[index - 1];
        return _MemberItem(member: member, myRole: myRole, userProfile: userProfile);
      },
    );
  }
}

class _MemberListHeader extends StatelessWidget {
  const _MemberListHeader();

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              LocaleKeys.settings_appearance_members_user.tr(),
              style: theme.textStyle.body.standard(color: theme.textColorScheme.secondary),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              LocaleKeys.settings_appearance_members_role.tr(),
              style: theme.textStyle.body.standard(color: theme.textColorScheme.secondary),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              LocaleKeys.settings_accountPage_email_title.tr(),
              style: theme.textStyle.body.standard(color: theme.textColorScheme.secondary),
            ),
          ),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

class _MemberItem extends StatelessWidget {
  final WorkspaceMemberPB member;
  final AFRolePB myRole;
  final UserProfilePB userProfile;

  const _MemberItem({
    required this.member,
    required this.myRole,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final bool canDelete = myRole.canDelete && member.email != userProfile.email;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                UserAvatar(iconUrl: member.avatarUrl, name: member.name, size: AFAvatarSize.s),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: theme.textStyle.body.enhanced(color: theme.textColorScheme.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatJoinedDate(member.joinedAt.toInt()),
                        style: theme.textStyle.caption.standard(color: theme.textColorScheme.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: member.role.isOwner || !myRole.canUpdate
                ? Text(
                    member.role.description,
                    style: theme.textStyle.body.standard(color: theme.textColorScheme.primary),
                  )
                : _MemberRoleActionList(member: member),
          ),
          Expanded(
            flex: 3,
            child: Tooltip(
              message: member.email,
              child: Text(
                member.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textStyle.body.standard(color: theme.textColorScheme.primary),
              ),
            ),
          ),
          canDelete ? _MemberMoreActionList(member: member) : const SizedBox(width: 28),
        ],
      ),
    );
  }

  String _formatJoinedDate(int timestampSeconds) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestampSeconds * 1000);
    return 'Joined on ${DateFormat('MMM d, y').format(date)}';
  }
}

enum _MemberMoreAction { delete }

class _MemberMoreActionList extends StatelessWidget {
  final WorkspaceMemberPB member;

  const _MemberMoreActionList({required this.member});

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<_MemberMoreActionWrapper>(
      asBarrier: true,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: _MemberMoreAction.values.map((e) => _MemberMoreActionWrapper(e, member)).toList(),
      buildChild: (controller) => FlowyButton(
        useIntrinsicWidth: true,
        text: const FlowySvg(FlowySvgs.three_dots_s),
        onTap: controller.show,
      ),
      onSelected: (action, controller) {
        if (action.inner == _MemberMoreAction.delete) {
          showCancelAndConfirmDialog(
            context: context,
            title: LocaleKeys.settings_appearance_members_removeMember.tr(),
            description: LocaleKeys.settings_appearance_members_areYouSureToRemoveMember.tr(),
            confirmLabel: LocaleKeys.button_yes.tr(),
            onConfirm: (_) => context.read<WorkspaceMemberBloc>().add(
              WorkspaceMemberEvent.removeWorkspaceMemberByEmail(action.member.email),
            ),
          );
        }
        controller.close();
      },
    );
  }
}

class _MemberMoreActionWrapper extends ActionCell {
  final _MemberMoreAction inner;
  final WorkspaceMemberPB member;

  _MemberMoreActionWrapper(this.inner, this.member);

  @override
  String get name {
    switch (inner) {
      case _MemberMoreAction.delete:
        return LocaleKeys.settings_appearance_members_removeFromWorkspace.tr();
    }
  }
}

class _MemberRoleActionList extends StatelessWidget {
  final WorkspaceMemberPB member;

  const _MemberRoleActionList({required this.member});

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    return Text(
      member.role.description,
      style: theme.textStyle.body.standard(color: theme.textColorScheme.primary),
    );
  }
}
