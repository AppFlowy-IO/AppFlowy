import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
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
              const _WorkspaceMoreButton(),
              const HSpace(8.0),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Divider(height: 1.0),
        ),
        // workspace list
        for (final workspace in workspaces) ...[
          WorkspaceMenuItem(
            key: ValueKey(workspace.workspaceId),
            workspace: workspace,
            userProfile: userProfile,
            isSelected: workspace.workspaceId == currentWorkspace.workspaceId,
          ),
          const VSpace(6.0),
        ],
        // add new workspace
        const _CreateWorkspaceButton(),
        const VSpace(6.0),
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
}

class WorkspaceMenuItem extends StatefulWidget {
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
  State<WorkspaceMenuItem> createState() => _WorkspaceMenuItemState();
}

class _WorkspaceMenuItemState extends State<WorkspaceMenuItem> {
  final ValueNotifier<bool> isHovered = ValueNotifier(false);

  @override
  void dispose() {
    isHovered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WorkspaceMemberBloc(
        userProfile: widget.userProfile,
        workspace: widget.workspace,
      )..add(const WorkspaceMemberEvent.initial()),
      child: BlocBuilder<WorkspaceMemberBloc, WorkspaceMemberState>(
        builder: (context, state) {
          // settings right icon inside the flowy button will
          //  cause the popover dismiss intermediately when click the right icon.
          // so using the stack to put the right icon on the flowy button.
          return SizedBox(
            height: 44,
            child: MouseRegion(
              onEnter: (_) => isHovered.value = true,
              onExit: (_) => isHovered.value = false,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  _WorkspaceInfo(
                    isSelected: widget.isSelected,
                    workspace: widget.workspace,
                  ),
                  Positioned(left: 4, child: _buildLeftIcon(context)),
                  Positioned(
                    right: 4.0,
                    child: Align(child: _buildRightIcon(context, isHovered)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeftIcon(BuildContext context) {
    return Container(
      width: 32.0,
      height: 32.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0x01717171).withOpacity(0.12),
          width: 0.8,
        ),
      ),
      child: FlowyTooltip(
        message: LocaleKeys.document_plugins_cover_changeIcon.tr(),
        child: WorkspaceIcon(
          workspace: widget.workspace,
          iconSize: 22,
          fontSize: 16,
          enableEdit: true,
          onSelected: (result) => context.read<UserWorkspaceBloc>().add(
                UserWorkspaceEvent.updateWorkspaceIcon(
                  widget.workspace.workspaceId,
                  result.emoji,
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildRightIcon(BuildContext context, ValueNotifier<bool> isHovered) {
    // only the owner can update or delete workspace.
    if (context.read<WorkspaceMemberBloc>().state.isLoading) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        ValueListenableBuilder(
          valueListenable: isHovered,
          builder: (context, value, child) {
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Opacity(
                opacity: value ? 1.0 : 0.0,
                child: child,
              ),
            );
          },
          child: WorkspaceMoreActionList(workspace: widget.workspace),
        ),
        const HSpace(8.0),
        if (widget.isSelected) ...[
          const Padding(
            padding: EdgeInsets.all(5.0),
            child: FlowySvg(
              FlowySvgs.workspace_selected_s,
              blendMode: null,
              size: Size.square(14.0),
            ),
          ),
          const HSpace(8.0),
        ],
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
          leftIconSize: const Size.square(32),
          leftIcon: const SizedBox.square(dimension: 32),
          rightIcon: const HSpace(32.0),
          text: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // workspace name
              FlowyText.medium(
                workspace.name,
                fontSize: 14.0,
                overflow: TextOverflow.ellipsis,
                withTooltip: true,
              ),
              if (Platform.isMacOS) const VSpace(2.0),
              // workspace members count
              FlowyText.regular(
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

class _CreateWorkspaceButton extends StatelessWidget {
  const _CreateWorkspaceButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: FlowyButton(
        key: createWorkspaceButtonKey,
        onTap: () {
          _showCreateWorkspaceDialog(context);
          PopoverContainer.of(context).closeAll();
        },
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        text: Row(
          children: [
            _buildLeftIcon(context),
            const HSpace(10.0),
            FlowyText.regular(LocaleKeys.workspace_create.tr()),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftIcon(BuildContext context) {
    return Container(
      width: 32.0,
      height: 32.0,
      padding: const EdgeInsets.all(7.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0x01717171).withOpacity(0.12),
          width: 0.8,
        ),
      ),
      child: const FlowySvg(FlowySvgs.add_workspace_s),
    );
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

class _WorkspaceMoreButton extends StatelessWidget {
  const _WorkspaceMoreButton();

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      direction: PopoverDirection.bottomWithLeftAligned,
      offset: const Offset(0, 6),
      popupBuilder: (_) => FlowyButton(
        margin: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 7.0),
        leftIcon: const FlowySvg(FlowySvgs.workspace_logout_s),
        iconPadding: 10.0,
        text: FlowyText.regular(LocaleKeys.button_logout.tr()),
        onTap: () async {
          await getIt<AuthService>().signOut();
          await runAppFlowy();
        },
      ),
      child: SizedBox.square(
        dimension: 24.0,
        child: FlowyButton(
          useIntrinsicWidth: true,
          margin: EdgeInsets.zero,
          text: const FlowySvg(
            FlowySvgs.workspace_three_dots_s,
            size: Size.square(16.0),
          ),
          onTap: () {},
        ),
      ),
    );
  }
}
