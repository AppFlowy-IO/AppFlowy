import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/home/mobile_home_setting_page.dart';
import 'package:appflowy/mobile/presentation/home/workspaces/workspace_menu_bottom_sheet.dart';
import 'package:appflowy/plugins/base/emoji/emoji_picker_screen.dart';
import 'package:appflowy/plugins/base/icon/icon_picker.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/built_in_svgs.dart';
import 'package:appflowy/workspace/application/user/settings_user_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/workspace/_sidebar_workspace_icon.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileHomePageHeader extends StatelessWidget {
  const MobileHomePageHeader({
    super.key,
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<SettingsUserViewBloc>(param1: userProfile)
        ..add(const SettingsUserEvent.initial()),
      child: BlocBuilder<SettingsUserViewBloc, SettingsUserState>(
        builder: (context, state) {
          final isCollaborativeWorkspace =
              context.read<UserWorkspaceBloc>().state.isCollabWorkspaceOn;
          return ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: isCollaborativeWorkspace
                      ? _MobileWorkspace(userProfile: userProfile)
                      : _MobileUser(userProfile: userProfile),
                ),
                GestureDetector(
                  onTap: () => context.push(
                    MobileHomeSettingPage.routeName,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: FlowySvg(FlowySvgs.m_setting_m),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MobileUser extends StatelessWidget {
  const _MobileUser({
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    final userIcon = userProfile.iconUrl;
    return Row(
      children: [
        _UserIcon(userIcon: userIcon),
        const HSpace(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FlowyText.medium('AppFlowy', fontSize: 18),
              const VSpace(4),
              FlowyText.regular(
                userProfile.email.isNotEmpty
                    ? userProfile.email
                    : userProfile.name,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileWorkspace extends StatelessWidget {
  const _MobileWorkspace({
    required this.userProfile,
  });

  final UserProfilePB userProfile;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
      builder: (context, state) {
        final currentWorkspace = state.currentWorkspace;
        if (currentWorkspace == null) {
          return const SizedBox.shrink();
        }
        return GestureDetector(
          onTap: () {
            context.read<UserWorkspaceBloc>().add(
                  const UserWorkspaceEvent.fetchWorkspaces(),
                );
            _showSwitchWorkspacesBottomSheet(context);
          },
          child: Row(
            children: [
              SizedBox.square(
                dimension: currentWorkspace.icon.isNotEmpty ? 34.0 : 26.0,
                child: WorkspaceIcon(
                  workspace: currentWorkspace,
                  iconSize: 26,
                  fontSize: 16.0,
                  enableEdit: false,
                  alignment: Alignment.centerLeft,
                  onSelected: (result) => context.read<UserWorkspaceBloc>().add(
                        UserWorkspaceEvent.updateWorkspaceIcon(
                          currentWorkspace.workspaceId,
                          result.emoji,
                        ),
                      ),
                ),
              ),
              currentWorkspace.icon.isNotEmpty
                  ? const HSpace(2)
                  : const HSpace(8),
              FlowyText.semibold(
                currentWorkspace.name,
                fontSize: 16.0,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSwitchWorkspacesBottomSheet(
    BuildContext context,
  ) {
    showMobileBottomSheet(
      context,
      showDivider: false,
      showHeader: true,
      showDragHandle: true,
      showCloseButton: true,
      title: LocaleKeys.workspace_menuTitle.tr(),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (_) {
        return BlocProvider.value(
          value: context.read<UserWorkspaceBloc>(),
          child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
            builder: (context, state) {
              final currentWorkspace = state.currentWorkspace;
              final workspaces = state.workspaces;
              if (currentWorkspace == null || workspaces.isEmpty) {
                return const SizedBox.shrink();
              }
              return MobileWorkspaceMenu(
                userProfile: userProfile,
                currentWorkspace: currentWorkspace,
                workspaces: workspaces,
                onWorkspaceSelected: (workspace) {
                  context.pop();

                  if (workspace == currentWorkspace) {
                    return;
                  }

                  context.read<UserWorkspaceBloc>().add(
                        UserWorkspaceEvent.openWorkspace(
                          workspace.workspaceId,
                        ),
                      );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _UserIcon extends StatelessWidget {
  const _UserIcon({
    required this.userIcon,
  });

  final String userIcon;

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      useIntrinsicWidth: true,
      text: builtInSVGIcons.contains(userIcon)
          // to be compatible with old user icon
          ? FlowySvg(
              FlowySvgData('emoji/$userIcon'),
              size: const Size.square(32),
              blendMode: null,
            )
          : FlowyText(
              userIcon.isNotEmpty ? userIcon : '🐻',
              fontSize: 26,
            ),
      onTap: () async {
        final icon = await context.push<EmojiPickerResult>(
          Uri(
            path: MobileEmojiPickerScreen.routeName,
            queryParameters: {
              MobileEmojiPickerScreen.pageTitle:
                  LocaleKeys.titleBar_userIcon.tr(),
            },
          ).toString(),
        );
        if (icon != null) {
          if (context.mounted) {
            context.read<SettingsUserViewBloc>().add(
                  SettingsUserEvent.updateUserIcon(
                    iconUrl: icon.emoji,
                  ),
                );
          }
        }
      },
    );
  }
}
