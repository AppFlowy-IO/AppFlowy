import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
          print('state.members: ${state.members}');
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // title
                const FlowyText('Members Settings'),
                const _InviteMember(),
                if (state.members.isNotEmpty) ...[
                  const FlowyText('Members'),
                  _MemberList(members: state.members, userProfile: userProfile),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InviteMember extends StatelessWidget {
  const _InviteMember({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FlowyText('Invite member'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: FlowyTextField(),
            ),
            HSpace(4.0),
            FlowyButton(
              useIntrinsicWidth: true,
              text: FlowyText('send invite'),
            ),
          ],
        ),
        FlowyButton(
          useIntrinsicWidth: true,
          text: FlowyText('Copy invite link'),
        ),
        Divider(),
      ],
    );
  }
}

class _MemberList extends StatelessWidget {
  const _MemberList({
    required this.members,
    required this.userProfile,
  });

  final List<WorkspaceMemberPB> members;
  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return SeparatedColumn(
      separatorBuilder: () => const Divider(),
      children: [
        const _MemberListHeader(),
        ...members.map(
          (member) => _MemberItem(
            member: member,
            isCurrentUser: member.email == userProfile.email,
          ),
        ),
      ],
    );
  }
}

class _MemberListHeader extends StatelessWidget {
  const _MemberListHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: FlowyText('User')),
        Expanded(child: FlowyText('Role')),
        HSpace(28.0),
      ],
    );
  }
}

class _MemberItem extends StatelessWidget {
  const _MemberItem({
    required this.member,
    required this.isCurrentUser,
  });

  final WorkspaceMemberPB member;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final textColor = isCurrentUser ? Theme.of(context).hintColor : null;
    return Row(
      children: [
        Expanded(
          child: FlowyText(
            member.name,
            color: textColor,
          ),
        ),
        Expanded(
          child: FlowyText(
            member.role.toString(),
            color: textColor,
          ),
        ),
        isCurrentUser
            ? const HSpace(28.0)
            : const FlowyButton(
                useIntrinsicWidth: true,
                text: FlowySvg(
                  FlowySvgs.delete_s,
                ),
              ),
      ],
    );
  }
}
