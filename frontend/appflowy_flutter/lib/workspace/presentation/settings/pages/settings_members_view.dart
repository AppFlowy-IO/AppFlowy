import 'package:flutter/material.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_actionable_input.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_body.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_category_spacer.dart';
import 'package:appflowy/workspace/presentation/settings/shared/settings_header.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/workspace.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:string_validator/string_validator.dart';

class SettingsMembersView extends StatefulWidget {
  const SettingsMembersView({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  State<SettingsMembersView> createState() => _SettingsMembersViewState();
}

class _SettingsMembersViewState extends State<SettingsMembersView> {
  final _inviteEmailController = TextEditingController();

  @override
  void dispose() {
    _inviteEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkspaceMemberBloc>(
      create: (context) => WorkspaceMemberBloc(userProfile: widget.userProfile)
        ..add(const WorkspaceMemberEvent.initial()),
      child: BlocConsumer<WorkspaceMemberBloc, WorkspaceMemberState>(
        listener: _showResultDialog,
        builder: (context, state) {
          return SettingsBody(
            children: [
              SettingsHeader(
                title: LocaleKeys.settings_appearance_members_title.tr(),
              ),
              if (state.myRole.canInvite)
                SettingsCategory(
                  title:
                      LocaleKeys.settings_appearance_members_inviteMembers.tr(),
                  children: [
                    SettingsActionableInput(
                      controller: _inviteEmailController,
                      actions: [
                        SizedBox(
                          height: 48,
                          child: FlowyTextButton(
                            LocaleKeys.settings_appearance_members_sendInvite
                                .tr(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            fontWeight: FontWeight.w600,
                            radius: BorderRadius.circular(12),
                            fillColor: Theme.of(context).colorScheme.primary,
                            hoverColor: const Color(0xFF005483),
                            fontHoverColor: Colors.white,
                            onPressed: () {
                              final email = _inviteEmailController.text;
                              if (!isEmail(email)) {
                                return showSnackBarMessage(
                                  context,
                                  LocaleKeys
                                      .settings_appearance_members_emailInvalidError
                                      .tr(),
                                );
                              }

                              context.read<WorkspaceMemberBloc>().add(
                                    WorkspaceMemberEvent.addWorkspaceMember(
                                      _inviteEmailController.text,
                                    ),
                                  );
                            },
                          ),
                        ),
                      ],
                    ),
                    /* Enable this when the feature is ready
                    PrimaryButton(
                      backgroundColor: const Color(0xFFE0E0E0),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          right: 24,
                          top: 8,
                          bottom: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FlowySvg(
                              FlowySvgs.invite_member_link_m,
                              color: Colors.black,
                            ),
                            const HSpace(8.0),
                            FlowyText(
                              LocaleKeys.settings_appearance_members_copyInviteLink.tr(),
                              color: Colors.black,
                            ),
                          ],
                        ),
                      ),
                      onPressed: () {
                        showSnackBarMessage(context, 'not implemented');
                      },
                    ),
                    const VSpace(16.0),
                    */
                  ],
                ),
              if (state.members.isNotEmpty) ...[
                const SettingsCategorySpacer(),
                SettingsCategory(
                  title: LocaleKeys.settings_appearance_members_label.tr(),
                  children: [
                    _MemberList(
                      members: state.members,
                      myRole: state.myRole,
                      userProfile: widget.userProfile,
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showResultDialog(BuildContext context, WorkspaceMemberState state) {
    final actionResult = state.actionResult;
    if (actionResult == null) {
      return;
    }

    final actionType = actionResult.actionType;
    final result = actionResult.result;

    // only show the result dialog when the action is WorkspaceMemberActionType.add
    if (actionType == WorkspaceMemberActionType.add) {
      result.fold(
        (_) => showSnackBarMessage(
          context,
          LocaleKeys.settings_appearance_members_addMemberSuccess.tr(),
        ),
        (error) => showDialog(
          context: context,
          builder: (_) => NavigatorOkCancelDialog(
            message: error.code == ErrorCode.WorkspaceMemberLimitExceeded
                ? LocaleKeys.settings_appearance_members_memberLimitExceeded
                    .tr()
                : LocaleKeys.settings_appearance_members_failedToAddMember.tr(),
          ),
        ),
      );
    }

    result.onFailure(
      (f) => Log.error(
        '[Member] Failed to perform ${actionType.toString()} action: $f',
      ),
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.members,
    required this.myRole,
    required this.userProfile,
  });

  final List<WorkspaceMemberPB> members;
  final AFRolePB myRole;
  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const VSpace(16.0),
        SeparatedColumn(
          crossAxisAlignment: CrossAxisAlignment.start,
          separatorBuilder: () => const Divider(),
          children: [
            const _MemberListHeader(),
            ...members.map(
              (member) => _MemberItem(
                member: member,
                myRole: myRole,
                userProfile: userProfile,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MemberListHeader extends StatelessWidget {
  const _MemberListHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FlowyText.semibold(
            LocaleKeys.settings_appearance_members_user.tr(),
            fontSize: 14.0,
          ),
        ),
        Expanded(
          child: FlowyText.semibold(
            LocaleKeys.settings_appearance_members_role.tr(),
            fontSize: 14.0,
          ),
        ),
        const HSpace(28.0),
      ],
    );
  }
}

class _MemberItem extends StatelessWidget {
  const _MemberItem({
    required this.member,
    required this.myRole,
    required this.userProfile,
  });

  final WorkspaceMemberPB member;
  final AFRolePB myRole;
  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    final textColor = member.role.isOwner ? Theme.of(context).hintColor : null;
    return Row(
      children: [
        Expanded(
          child: FlowyText.medium(
            member.name,
            color: textColor,
            fontSize: 14.0,
          ),
        ),
        Expanded(
          child: member.role.isOwner || !myRole.canUpdate
              ? FlowyText.medium(
                  member.role.description,
                  color: textColor,
                  fontSize: 14.0,
                )
              : _MemberRoleActionList(member: member),
        ),
        myRole.canDelete &&
                member.email != userProfile.email // can't delete self
            ? _MemberMoreActionList(member: member)
            : const HSpace(28.0),
      ],
    );
  }
}

enum _MemberMoreAction { delete }

class _MemberMoreActionList extends StatelessWidget {
  const _MemberMoreActionList({required this.member});

  final WorkspaceMemberPB member;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<_MemberMoreActionWrapper>(
      asBarrier: true,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: _MemberMoreAction.values
          .map((e) => _MemberMoreActionWrapper(e, member))
          .toList(),
      buildChild: (controller) => FlowyButton(
        useIntrinsicWidth: true,
        text: const FlowySvg(FlowySvgs.three_dots_vertical_s),
        onTap: controller.show,
      ),
      onSelected: (action, controller) {
        switch (action.inner) {
          case _MemberMoreAction.delete:
            showDialog(
              context: context,
              builder: (_) => NavigatorOkCancelDialog(
                title: LocaleKeys.settings_appearance_members_removeMember.tr(),
                message: LocaleKeys
                    .settings_appearance_members_areYouSureToRemoveMember
                    .tr(),
                okTitle: LocaleKeys.button_yes.tr(),
                onOkPressed: () => context.read<WorkspaceMemberBloc>().add(
                      WorkspaceMemberEvent.removeWorkspaceMember(
                        action.member.email,
                      ),
                    ),
              ),
            );
            break;
        }
        controller.close();
      },
    );
  }
}

class _MemberMoreActionWrapper extends ActionCell {
  _MemberMoreActionWrapper(this.inner, this.member);

  final _MemberMoreAction inner;
  final WorkspaceMemberPB member;

  @override
  String get name => switch (inner) {
        _MemberMoreAction.delete =>
          LocaleKeys.settings_appearance_members_removeFromWorkspace.tr(),
      };
}

class _MemberRoleActionList extends StatelessWidget {
  const _MemberRoleActionList({required this.member});

  final WorkspaceMemberPB member;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<_MemberRoleActionWrapper>(
      asBarrier: true,
      direction: PopoverDirection.bottomWithLeftAligned,
      actions: [_MemberRoleActionWrapper(AFRolePB.Member, member)],
      offset: const Offset(0, 10),
      buildChild: (controller) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: controller.show,
          child: Row(
            children: [
              FlowyText.medium(member.role.description, fontSize: 14.0),
              const HSpace(8.0),
              const FlowySvg(FlowySvgs.drop_menu_show_s),
            ],
          ),
        ),
      ),
      onSelected: (action, controller) {
        switch (action.inner) {
          case AFRolePB.Member:
          case AFRolePB.Guest:
            context.read<WorkspaceMemberBloc>().add(
                  WorkspaceMemberEvent.updateWorkspaceMember(
                    action.member.email,
                    action.inner,
                  ),
                );
            break;
          case AFRolePB.Owner:
            break;
        }
        controller.close();
      },
    );
  }
}

class _MemberRoleActionWrapper extends ActionCell {
  _MemberRoleActionWrapper(this.inner, this.member);

  final AFRolePB inner;
  final WorkspaceMemberPB member;

  @override
  Widget? rightIcon(Color iconColor) {
    return SizedBox(
      width: 58.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FlowyTooltip(
            message: tooltip,
            child: const FlowySvg(FlowySvgs.information_s),
          ),
          const Spacer(),
          if (member.role == inner) const FlowySvg(FlowySvgs.checkmark_tiny_s),
        ],
      ),
    );
  }

  @override
  String get name => switch (inner) {
        AFRolePB.Guest => LocaleKeys.settings_appearance_members_guest.tr(),
        AFRolePB.Member => LocaleKeys.settings_appearance_members_member.tr(),
        AFRolePB.Owner => LocaleKeys.settings_appearance_members_owner.tr(),
        _ => throw UnimplementedError('Unknown role: $inner'),
      };

  String get tooltip => switch (inner) {
        AFRolePB.Guest =>
          LocaleKeys.settings_appearance_members_guestHintText.tr(),
        AFRolePB.Member =>
          LocaleKeys.settings_appearance_members_memberHintText.tr(),
        AFRolePB.Owner => '',
        _ => throw UnimplementedError('Unknown role: $inner'),
      };
}
