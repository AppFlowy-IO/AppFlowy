import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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

    Widget child = Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
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
      ),
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

enum _MemberMoreAction {
  delete,
}

class _MemberMoreActionList extends StatelessWidget {
  const _MemberMoreActionList({
    required this.member,
  });

  final WorkspaceMemberPB member;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<_MemberMoreActionWrapper>(
      asBarrier: true,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: _MemberMoreAction.values
          .map((e) => _MemberMoreActionWrapper(e, member))
          .toList(),
      buildChild: (controller) {
        return FlowyButton(
          useIntrinsicWidth: true,
          text: const FlowySvg(
            FlowySvgs.three_dots_vertical_s,
          ),
          onTap: () {
            controller.show();
          },
        );
      },
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
                onOkPressed: () => context.read<WorkspaceMemberBloc>().add(
                      WorkspaceMemberEvent.removeWorkspaceMember(
                        action.member.email,
                      ),
                    ),
                okTitle: LocaleKeys.button_yes.tr(),
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
  String get name {
    switch (inner) {
      case _MemberMoreAction.delete:
        return LocaleKeys.settings_appearance_members_removeFromWorkspace.tr();
    }
  }
}

class _MemberRoleActionList extends StatelessWidget {
  const _MemberRoleActionList({
    required this.member,
  });

  final WorkspaceMemberPB member;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<_MemberRoleActionWrapper>(
      asBarrier: true,
      direction: PopoverDirection.bottomWithLeftAligned,
      actions: [AFRolePB.Member]
          .map((e) => _MemberRoleActionWrapper(e, member))
          .toList(),
      offset: const Offset(0, 10),
      buildChild: (controller) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => controller.show(),
            child: Row(
              children: [
                FlowyText.medium(
                  member.role.description,
                  fontSize: 14.0,
                ),
                const HSpace(8.0),
                const FlowySvg(
                  FlowySvgs.drop_menu_show_s,
                ),
              ],
            ),
          ),
        );
      },
      onSelected: (action, controller) async {
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
            child: const FlowySvg(
              FlowySvgs.information_s,
              // color: iconColor,
            ),
          ),
          const Spacer(),
          if (member.role == inner)
            const FlowySvg(
              FlowySvgs.checkmark_tiny_s,
            ),
        ],
      ),
    );
  }

  @override
  String get name {
    switch (inner) {
      case AFRolePB.Guest:
        return LocaleKeys.settings_appearance_members_guest.tr();
      case AFRolePB.Member:
        return LocaleKeys.settings_appearance_members_member.tr();
      case AFRolePB.Owner:
        return LocaleKeys.settings_appearance_members_owner.tr();
    }
    throw UnimplementedError('Unknown role: $inner');
  }

  String get tooltip {
    switch (inner) {
      case AFRolePB.Guest:
        return LocaleKeys.settings_appearance_members_guestHintText.tr();
      case AFRolePB.Member:
        return LocaleKeys.settings_appearance_members_memberHintText.tr();
      case AFRolePB.Owner:
        return '';
    }
    throw UnimplementedError('Unknown role: $inner');
  }
}
