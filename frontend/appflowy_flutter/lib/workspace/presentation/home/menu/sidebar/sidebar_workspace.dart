import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_item_list.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_button.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SidebarWorkspace extends StatelessWidget {
  const SidebarWorkspace({
    super.key,
    required this.userProfile,
    required this.views,
  });

  final UserProfilePB userProfile;
  final List<ViewPB> views;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserWorkspaceBloc>(
      create: (_) => UserWorkspaceBloc(userProfile: userProfile)
        ..add(const UserWorkspaceEvent.fetchWorkspaces()),
      child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
        builder: (context, state) {
          final currentWorkspace = state.currentWorkspace;
          // todo: show something if there is no workspace
          if (currentWorkspace == null) {
            return const SizedBox.shrink();
          }
          return Row(
            children: [
              Expanded(
                child: _WorkspaceWrapper(
                  userProfile: userProfile,
                  currentWorkspace: currentWorkspace,
                ),
              ),
              UserSettingButton(userProfile: userProfile),
              const HSpace(4),
              NotificationButton(views: views),
            ],
          );
        },
      ),
    );
  }
}

class _WorkspaceWrapper extends StatefulWidget {
  const _WorkspaceWrapper({
    required this.userProfile,
    required this.currentWorkspace,
  });

  final UserWorkspacePB currentWorkspace;
  final UserProfilePB userProfile;

  @override
  State<_WorkspaceWrapper> createState() => _WorkspaceWrapperState();
}

class _WorkspaceWrapperState extends State<_WorkspaceWrapper> {
  final controller = PopoverController();

  @override
  Widget build(BuildContext context) {
    if (PlatformExtension.isDesktopOrWeb) {
      return AppFlowyPopover(
        direction: PopoverDirection.bottomWithCenterAligned,
        offset: const Offset(0, 10),
        constraints: const BoxConstraints(maxWidth: 260, maxHeight: 600),
        popupBuilder: (_) {
          return BlocProvider<UserWorkspaceBloc>.value(
            value: context.read<UserWorkspaceBloc>(),
            child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
              builder: (context, state) {
                final currentWorkspace = state.currentWorkspace;
                final workspaces = state.workspaces;
                if (currentWorkspace == null || workspaces.isEmpty) {
                  return const SizedBox.shrink();
                }
                return WorkspacesMenu(
                  userProfile: widget.userProfile,
                  currentWorkspace: currentWorkspace,
                  workspaces: workspaces,
                );
              },
            ),
          );
        },
        child: FlowyButton(
          onTap: () => controller.show(),
          margin: const EdgeInsets.symmetric(vertical: 8),
          text: Row(
            children: [
              const HSpace(4.0),
              SizedBox(
                width: 24.0,
                child: WorkspaceIcon(workspace: widget.currentWorkspace),
              ),
              const HSpace(8),
              FlowyText.medium(
                widget.currentWorkspace.name,
                overflow: TextOverflow.ellipsis,
              ),
              const FlowySvg(FlowySvgs.drop_menu_show_m),
            ],
          ),
        ),
      );
    } else {
      // TODO: Lucas.Xu. mobile workspace menu
      return const Placeholder();
    }
  }
}
