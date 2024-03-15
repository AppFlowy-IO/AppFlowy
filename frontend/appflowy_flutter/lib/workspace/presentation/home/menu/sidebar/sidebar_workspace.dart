import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/sidebar_setting.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_menu.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/notifications/widgets/notification_button.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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
    return BlocConsumer<UserWorkspaceBloc, UserWorkspaceState>(
      listener: _showResultDialog,
      builder: (context, state) {
        final currentWorkspace = state.currentWorkspace;
        // todo: show something if there is no workspace
        if (currentWorkspace == null) {
          return const SizedBox.shrink();
        }
        return Row(
          children: [
            Expanded(
              child: SidebarWorkspaceWrapper(
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
    );
  }

  void _showResultDialog(BuildContext context, UserWorkspaceState state) {
    var result = state.createWorkspaceResult;

    if (result != null) {
      final message = result.fold(
        (s) => LocaleKeys.workspace_createSuccess.tr(),
        (e) => '${LocaleKeys.workspace_createFailed.tr()}: ${e.msg}',
      );
      return showSnackBarMessage(context, message);
    }

    result = state.deleteWorkspaceResult;
    if (result != null) {
      final message = result.fold(
        (s) => LocaleKeys.workspace_deleteSuccess.tr(),
        (e) => '${LocaleKeys.workspace_deleteFailed.tr()}: ${e.msg}',
      );
      showSnackBarMessage(context, message);
      return;
    }

    result = state.openWorkspaceResult;
    if (result != null) {
      final message = result.fold(
        (s) => LocaleKeys.workspace_openSuccess.tr(),
        (e) => '${LocaleKeys.workspace_openFailed.tr()}: ${e.msg}',
      );
      showSnackBarMessage(context, message);
      return;
    }

    result = state.updateWorkspaceIconResult;
    if (result != null) {
      final message = result.fold(
        (s) => LocaleKeys.workspace_updateIconSuccess.tr(),
        (e) => '${LocaleKeys.workspace_updateIconFailed.tr()}: ${e.msg}',
      );
      showSnackBarMessage(context, message);
      return;
    }

    result = state.renameWorkspaceResult;
    if (result != null) {
      final message = result.fold(
        (s) => LocaleKeys.workspace_renameSuccess.tr(),
        (e) => '${LocaleKeys.workspace_renameFailed.tr()}: ${e.msg}',
      );
      showSnackBarMessage(context, message);
      return;
    }
  }
}

class SidebarWorkspaceWrapper extends StatefulWidget {
  const SidebarWorkspaceWrapper({
    super.key,
    required this.userProfile,
    required this.currentWorkspace,
  });

  final UserWorkspacePB currentWorkspace;
  final UserProfilePB userProfile;

  @override
  State<SidebarWorkspaceWrapper> createState() =>
      _SidebarWorkspaceWrapperState();
}

class _SidebarWorkspaceWrapperState extends State<SidebarWorkspaceWrapper> {
  @override
  Widget build(BuildContext context) {
    if (PlatformExtension.isDesktopOrWeb) {
      return _DesktopWorkspaceWrapper(
        userProfile: widget.userProfile,
        currentWorkspace: widget.currentWorkspace,
      );
    } else {
      // TODO(Lucas) mobile workspace menu
      return const Placeholder();
    }
  }
}

class _DesktopWorkspaceWrapper extends StatefulWidget {
  const _DesktopWorkspaceWrapper({
    required this.userProfile,
    required this.currentWorkspace,
  });

  final UserWorkspacePB currentWorkspace;
  final UserProfilePB userProfile;

  @override
  State<_DesktopWorkspaceWrapper> createState() =>
      _DesktopWorkspaceWrapperState();
}

class _DesktopWorkspaceWrapperState extends State<_DesktopWorkspaceWrapper> {
  final controller = PopoverController();

  @override
  Widget build(BuildContext context) {
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
        useIntrinsicWidth: true,
        margin: const EdgeInsets.symmetric(vertical: 8),
        text: Row(
          children: [
            const HSpace(2.0),
            SizedBox.square(
              dimension: 28.0,
              child: WorkspaceIcon(
                workspace: widget.currentWorkspace,
                iconSize: 18,
                enableEdit: false,
              ),
            ),
            const HSpace(4),
            Expanded(
              child: FlowyText.medium(
                widget.currentWorkspace.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const FlowySvg(FlowySvgs.drop_menu_show_m),
          ],
        ),
      ),
    );
  }
}
