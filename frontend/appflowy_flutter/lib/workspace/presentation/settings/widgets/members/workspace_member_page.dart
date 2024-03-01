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
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // title
                const FlowyText('Members Settings'),
                const _InviteMember(),
                if (state.members.isNotEmpty)
                  _MemberList(members: state.members),
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
  });

  final List<WorkspaceMemberPB> members;

  @override
  Widget build(BuildContext context) {
    return SeparatedColumn(
      separatorBuilder: () => const Divider(),
      children: members
          .map(
            (member) => _MemberItem(member: member),
          )
          .toList(),
    );
  }
}

class _MemberItem extends StatelessWidget {
  const _MemberItem({
    required this.member,
  });

  final WorkspaceMemberPB member;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: FlowyText(member.name)),
        Expanded(child: FlowyText(member.role.toString())),
        const FlowyButton(
          useIntrinsicWidth: true,
          text: FlowySvg(FlowySvgs.delete_s),
        ),
      ],
    );
  }
}
