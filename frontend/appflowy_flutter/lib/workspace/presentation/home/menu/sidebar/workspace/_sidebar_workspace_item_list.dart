import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/af_role_pb_extension.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class WorkspacesMenu extends StatelessWidget {
  const WorkspacesMenu({
    super.key,
    required this.userProfile,
    required this.currentWorkspace,
    required this.workspaces,
  });

  final UserProfilePB userProfile;
  final UserWorkspacePB currentWorkspace;
  final List<UserWorkspacePB> workspaces;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // user email
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              FlowyText.medium(
                _getUserInfo(),
                fontSize: 12.0,
                overflow: TextOverflow.ellipsis,
                color: Theme.of(context).hintColor,
              ),
              const Spacer(),
              FlowyButton(
                useIntrinsicWidth: true,
                text: const FlowySvg(FlowySvgs.add_m),
                onTap: () {
                  _showCreateWorkspaceDialog(context);
                  PopoverContainer.of(context).closeAll();
                },
              ),
            ],
          ),
        ),
        for (final workspace in workspaces) ...[
          _WorkspaceMenuItem(
            workspace: workspace,
            userProfile: userProfile,
            isSelected: workspace.workspaceId == currentWorkspace.workspaceId,
          ),
          const VSpace(4.0),
        ],
      ],
    );
  }

  String _getUserInfo() {
    if (userProfile.email.isNotEmpty) {
      return userProfile.email;
    }

    if (userProfile.name.isNotEmpty) {
      return userProfile.name;
    }

    return LocaleKeys.defaultUsername.tr();
  }

  Future<void> _showCreateWorkspaceDialog(BuildContext context) async {
    if (context.mounted) {
      await NavigatorTextFieldDialog(
        title: LocaleKeys.workspace_create.tr(),
        value: '',
        hintText: '',
        autoSelectAllText: true,
        onConfirm: (name, context) async {
          final request = CreateWorkspacePB.create()..name = name;
          final result = await UserEventCreateWorkspace(request).send();
          final message = result.fold(
            (s) => LocaleKeys.workspace_createSuccess.tr(),
            (e) => '${LocaleKeys.workspace_createFailed.tr()}: ${e.msg}',
          );
          if (context.mounted) {
            showSnackBarMessage(context, message);
          }
        },
      ).show(context);
    }
  }
}

class _WorkspaceMenuItem extends StatelessWidget {
  const _WorkspaceMenuItem({
    required this.workspace,
    required this.userProfile,
    required this.isSelected,
  });

  final UserProfilePB userProfile;
  final UserWorkspacePB workspace;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          WorkspaceMemberBloc(userProfile: userProfile, workspace: workspace)
            ..add(const WorkspaceMemberEvent.initial())
            ..add(const WorkspaceMemberEvent.getWorkspaceMembers()),
      child: BlocBuilder<WorkspaceMemberBloc, WorkspaceMemberState>(
        builder: (context, state) {
          final members = state.members;
          // settings right icon inside the flowy button will
          //  cause the popover dismiss intermediately when click the right icon.
          // so using the stack to put the right icon on the flowy button.
          return Stack(
            alignment: Alignment.center,
            children: [
              FlowyButton(
                onTap: () {
                  if (!isSelected) {
                    context.read<UserWorkspaceBloc>().add(
                          UserWorkspaceEvent.openWorkspace(
                            workspace.workspaceId,
                          ),
                        );
                  }
                },
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                iconPadding: 10.0,
                leftIconSize: const Size.square(32),
                leftIcon: WorkspaceIcon(
                  workspace: workspace,
                ),
                text: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlowyText.medium(
                      workspace.name,
                      fontSize: 14.0,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (members.length > 1)
                      FlowyText(
                        '${members.length} ${LocaleKeys.settings_appearance_members_members.tr()}',
                        fontSize: 10.0,
                        color: Theme.of(context).hintColor,
                      ),
                  ],
                ),
              ),
              Positioned(
                right: 12.0,
                child: Align(child: _buildRightIcon(context)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRightIcon(BuildContext context) {
    // only the owner can update or delete workspace.
    // only show the more action button when the workspace is selected.
    if (!isSelected ||
        !context.read<WorkspaceMemberBloc>().state.myRole.isOwner) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        WorkspaceMoreActionList(workspace: workspace),
        const FlowySvg(
          FlowySvgs.blue_check_s,
          blendMode: null,
        ),
      ],
    );
  }
}
