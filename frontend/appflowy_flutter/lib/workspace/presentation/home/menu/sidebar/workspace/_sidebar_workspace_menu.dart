import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_actions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/settings/widgets/members/workspace_member_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@visibleForTesting
const createWorkspaceButtonKey = ValueKey('createWorkspaceButton');

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
              Expanded(
                child: FlowyText.medium(
                  _getUserInfo(),
                  fontSize: 12.0,
                  overflow: TextOverflow.ellipsis,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const HSpace(4.0),
              FlowyButton(
                key: createWorkspaceButtonKey,
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
          WorkspaceMenuItem(
            key: ValueKey(workspace.workspaceId),
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
      final workspaceBloc = context.read<UserWorkspaceBloc>();
      await CreateWorkspaceDialog(
        onConfirm: (name) {
          workspaceBloc.add(UserWorkspaceEvent.createWorkspace(name));
        },
      ).show(context);
    }
  }
}

class WorkspaceMenuItem extends StatelessWidget {
  const WorkspaceMenuItem({
    super.key,
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
            ..add(const WorkspaceMemberEvent.initial()),
      child: BlocBuilder<WorkspaceMemberBloc, WorkspaceMemberState>(
        builder: (context, state) {
          // settings right icon inside the flowy button will
          //  cause the popover dismiss intermediately when click the right icon.
          // so using the stack to put the right icon on the flowy button.
          return SizedBox(
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                _WorkspaceInfo(
                  isSelected: isSelected,
                  workspace: workspace,
                ),
                Positioned(left: 8, child: _buildLeftIcon(context)),
                Positioned(
                  right: 12.0,
                  child: Align(child: _buildRightIcon(context)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftIcon(BuildContext context) {
    return SizedBox.square(
      dimension: 32,
      child: FlowyTooltip(
        message: LocaleKeys.document_plugins_cover_changeIcon.tr(),
        child: WorkspaceIcon(
          workspace: workspace,
          iconSize: 26,
          enableEdit: true,
        ),
      ),
    );
  }

  Widget _buildRightIcon(BuildContext context) {
    // only the owner can update or delete workspace.
    // only show the more action button when the workspace is selected.
    if (!isSelected || context.read<WorkspaceMemberBloc>().state.isLoading) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        WorkspaceMoreActionList(workspace: workspace),
        const FlowySvg(
          FlowySvgs.blue_check_s,
        ),
      ],
    );
  }
}

class _WorkspaceInfo extends StatelessWidget {
  const _WorkspaceInfo({
    required this.isSelected,
    required this.workspace,
  });

  final bool isSelected;
  final UserWorkspacePB workspace;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkspaceMemberBloc, WorkspaceMemberState>(
      builder: (context, state) {
        final members = state.members;
        return FlowyButton(
          onTap: () => _openWorkspace(context),
          iconPadding: 10.0,
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          leftIconSize: const Size.square(32),
          leftIcon: const SizedBox.square(dimension: 32),
          rightIcon: const HSpace(42.0),
          text: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // workspace name
              FlowyText.medium(
                workspace.name,
                fontSize: 14.0,
                overflow: TextOverflow.ellipsis,
                withTooltip: true,
              ),
              // workspace members count
              FlowyText(
                state.isLoading
                    ? ''
                    : LocaleKeys.settings_appearance_members_membersCount
                        .plural(
                        members.length,
                      ),
                fontSize: 10.0,
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        );
      },
    );
  }

  void _openWorkspace(BuildContext context) {
    if (!isSelected) {
      Log.info('open workspace: ${workspace.workspaceId}');
      context.read<UserWorkspaceBloc>().add(
            UserWorkspaceEvent.openWorkspace(
              workspace.workspaceId,
            ),
          );
      PopoverContainer.of(context).closeAll();
    }
  }
}

class CreateWorkspaceDialog extends StatelessWidget {
  const CreateWorkspaceDialog({
    super.key,
    required this.onConfirm,
  });

  final void Function(String name) onConfirm;

  @override
  Widget build(BuildContext context) {
    return NavigatorTextFieldDialog(
      title: LocaleKeys.workspace_create.tr(),
      value: '',
      hintText: '',
      autoSelectAllText: true,
      onConfirm: (name, _) => onConfirm(name),
    );
  }
}
