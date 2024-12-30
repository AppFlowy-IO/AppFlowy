import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:universal_platform/universal_platform.dart';

class MobileMemberList extends StatelessWidget {
  const MobileMemberList({
    super.key,
    required this.members,
    required this.myRole,
    required this.userProfile,
  });

  final List<WorkspaceMemberPB> members;
  final AFRolePB myRole;
  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return SlidableAutoCloseBehavior(
      child: SeparatedColumn(
        crossAxisAlignment: CrossAxisAlignment.start,
        separatorBuilder: () => const FlowyDivider(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: FlowyText.semibold(
              LocaleKeys.settings_appearance_members_label.tr(),
              fontSize: 16.0,
            ),
          ),
          ...members.map(
            (member) => _MemberItem(
              member: member,
              myRole: myRole,
              userProfile: userProfile,
            ),
          ),
        ],
      ),
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
    final canDelete = myRole.canDelete && member.email != userProfile.email;
    final textColor = member.role.isOwner ? Theme.of(context).hintColor : null;

    Widget child;

    if (UniversalPlatform.isDesktop) {
      child = Row(
        children: [
          Expanded(
            child: FlowyText.medium(
              member.name,
              color: textColor,
              fontSize: 15.0,
            ),
          ),
          Expanded(
            child: FlowyText.medium(
              member.role.description,
              color: textColor,
              fontSize: 15.0,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      );
    } else {
      child = Row(
        children: [
          Expanded(
            child: FlowyText.medium(
              member.name,
              color: textColor,
              fontSize: 15.0,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(36.0),
          FlowyText.medium(
            member.role.description,
            color: textColor,
            fontSize: 15.0,
            textAlign: TextAlign.end,
          ),
        ],
      );
    }

    child = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: child,
    );

    if (canDelete) {
      child = Slidable(
        key: ValueKey(member.email),
        endActionPane: ActionPane(
          extentRatio: 1 / 6.0,
          motion: const ScrollMotion(),
          children: [
            CustomSlidableAction(
              backgroundColor: const Color(0xE5515563),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
              onPressed: (context) {
                HapticFeedback.mediumImpact();
                _showDeleteMenu(context);
              },
              padding: EdgeInsets.zero,
              child: const FlowySvg(
                FlowySvgs.three_dots_s,
                size: Size.square(24),
                color: Colors.white,
              ),
            ),
          ],
        ),
        child: child,
      );
    }

    return child;
  }

  void _showDeleteMenu(BuildContext context) {
    final workspaceMemberBloc = context.read<WorkspaceMemberBloc>();
    showMobileBottomSheet(
      context,
      showDragHandle: true,
      showDivider: false,
      useRootNavigator: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return FlowyOptionTile.text(
          text: LocaleKeys.settings_appearance_members_removeFromWorkspace.tr(),
          height: 52.0,
          textColor: Theme.of(context).colorScheme.error,
          leftIcon: FlowySvg(
            FlowySvgs.trash_s,
            size: const Size.square(18),
            color: Theme.of(context).colorScheme.error,
          ),
          showTopBorder: false,
          showBottomBorder: false,
          onTap: () {
            workspaceMemberBloc.add(
              WorkspaceMemberEvent.removeWorkspaceMember(
                member.email,
              ),
            );
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}
