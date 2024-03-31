import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/home/home.dart';
import 'package:appflowy/mobile/presentation/home/mobile_folders.dart';
import 'package:appflowy/mobile/presentation/home/mobile_home_page_header.dart';
import 'package:appflowy/mobile/presentation/home/recent_folder/mobile_home_recent_views.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy/workspace/presentation/home/errors/workspace_failed_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({super.key});

  static const routeName = '/home';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        FolderEventGetCurrentWorkspaceSetting().send(),
        getIt<AuthService>().getUser(),
      ]),
      builder: (context, snapshots) {
        if (!snapshots.hasData) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final workspaceSetting = snapshots.data?[0].fold(
          (workspaceSettingPB) {
            return workspaceSettingPB as WorkspaceSettingPB?;
          },
          (error) => null,
        );
        final userProfile = snapshots.data?[1].fold(
          (userProfilePB) {
            return userProfilePB as UserProfilePB?;
          },
          (error) => null,
        );

        // In the unlikely case either of the above is null, eg.
        // when a workspace is already open this can happen.
        if (workspaceSetting == null || userProfile == null) {
          return const WorkspaceFailedScreen();
        }

        return Scaffold(
          body: SafeArea(
            child: Provider.value(
              value: userProfile,
              child: MobileHomePage(
                userProfile: userProfile,
                workspaceSetting: workspaceSetting,
              ),
            ),
          ),
        );
      },
    );
  }
}

class MobileHomePage extends StatelessWidget {
  const MobileHomePage({
    super.key,
    required this.userProfile,
    required this.workspaceSetting,
  });

  final UserProfilePB userProfile;
  final WorkspaceSettingPB workspaceSetting;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UserWorkspaceBloc(userProfile: userProfile)
        ..add(
          const UserWorkspaceEvent.initial(),
        ),
      child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
        buildWhen: (previous, current) =>
            previous.currentWorkspace?.workspaceId !=
            current.currentWorkspace?.workspaceId,
        builder: (context, state) {
          if (state.currentWorkspace == null) {
            return const SizedBox.shrink();
          }
          return Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: Platform.isAndroid ? 8.0 : 0.0,
                ),
                child: MobileHomePageHeader(
                  userProfile: userProfile,
                ),
              ),
              const Divider(),

              // Folder
              Expanded(
                child: Scrollbar(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Recent files
                          const MobileRecentFolder(),

                          // Folders
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: MobileFolders(
                              user: userProfile,
                              workspaceId:
                                  state.currentWorkspace?.workspaceId ??
                                      workspaceSetting.workspaceId,
                              showFavorite: false,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: _TrashButton(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrashButton extends StatelessWidget {
  const _TrashButton();

  @override
  Widget build(BuildContext context) {
    return FlowyButton(
      expand: true,
      margin: const EdgeInsets.symmetric(vertical: 8),
      leftIcon: FlowySvg(
        FlowySvgs.m_delete_m,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      leftIconSize: const Size.square(24),
      text: FlowyText.medium(
        LocaleKeys.trash_text.tr(),
        fontSize: 18.0,
      ),
      onTap: () => context.push(MobileHomeTrashPage.routeName),
    );
  }
}
