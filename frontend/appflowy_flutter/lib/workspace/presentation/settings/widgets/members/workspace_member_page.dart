import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/buttons/primary_button.dart';
import 'package:flowy_infra_ui/widget/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkspaceMembersPage extends StatelessWidget {
  const WorkspaceMembersPage({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkspaceMemberBloc>(
      create: (context) => WorkspaceMemberBloc(userProfile: userProfile)
        ..add(
          const WorkspaceMemberEvent.getWorkspaceMembers(),
        ),
      child: BlocBuilder<WorkspaceMemberBloc, WorkspaceMemberState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // title
                FlowyText.semibold(
                  LocaleKeys.settings_appearance_members_title.tr(),
                  fontSize: 20,
                ),
                if (state.myRole.canInvite) const _InviteMember(),
                if (state.members.isNotEmpty)
                  _MemberList(
                    members: state.members,
                    userProfile: userProfile,
                    myRole: state.myRole,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InviteMember extends StatelessWidget {
  const _InviteMember();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const VSpace(12.0),
        FlowyText.semibold(
          LocaleKeys.settings_appearance_members_inviteMembers.tr(),
          fontSize: 16.0,
        ),
        const VSpace(8.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints.tightFor(
                  height: 48.0,
                ),
                child: const FlowyTextField(),
              ),
            ),
            const HSpace(10.0),
            SizedBox(
              height: 48.0,
              child: IntrinsicWidth(
                child: RoundedTextButton(
                  title: LocaleKeys.settings_appearance_members_sendInvite.tr(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
        const VSpace(16.0),
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
        const Divider(
          height: 1.0,
          thickness: 1.0,
        ),
      ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText.semibold(
          LocaleKeys.settings_appearance_members_label.tr(),
          fontSize: 16.0,
        ),
        const VSpace(16.0),
        Row(
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
        ),
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
    final textColor = myRole.isOwner ? Theme.of(context).hintColor : null;
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
          child: FlowyText.medium(
            member.role.description,
            color: textColor,
            fontSize: 14.0,
          ),
        ),
        myRole.canDelete &&
                member.email != userProfile.email // can't delete self
            ? const FlowyButton(
                useIntrinsicWidth: true,
                text: FlowySvg(
                  FlowySvgs.delete_s,
                ),
              )
            : const HSpace(28.0),
      ],
    );
  }
}

extension on AFRolePB {
  bool get isOwner => this == AFRolePB.Owner;

  bool get isMember => this == AFRolePB.Member;

  // bool get isGuest => this == AFRolePB.Guest;

  bool get canInvite => isOwner || isMember;

  bool get canDelete => isOwner;

  // bool get canUpdate => isOwner;

  String get description {
    switch (this) {
      case AFRolePB.Owner:
        return LocaleKeys.settings_appearance_members_owner.tr();
      case AFRolePB.Member:
        return LocaleKeys.settings_appearance_members_member.tr();
      case AFRolePB.Guest:
        return LocaleKeys.settings_appearance_members_guest.tr();
    }
    throw UnimplementedError('Unknown role: $this');
  }
}
