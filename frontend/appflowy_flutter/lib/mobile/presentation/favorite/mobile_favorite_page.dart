import 'dart:io';

import 'package:appflowy/mobile/presentation/favorite/mobile_favorite_folder.dart';
import 'package:appflowy/mobile/presentation/home/mobile_home_page_header.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/application/user/prelude.dart';
import 'package:appflowy/workspace/presentation/home/errors/workspace_failed_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileFavoriteScreen extends StatelessWidget {
  const MobileFavoriteScreen({
    super.key,
  });

  static const routeName = '/favorite';

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
            child: BlocProvider(
              create: (_) => UserWorkspaceBloc(userProfile: userProfile)
                ..add(
                  const UserWorkspaceEvent.initial(),
                ),
              child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
                buildWhen: (previous, current) =>
                    previous.currentWorkspace?.workspaceId !=
                    current.currentWorkspace?.workspaceId,
                builder: (context, state) {
                  return MobileFavoritePage(
                    userProfile: userProfile,
                    workspaceId: state.currentWorkspace?.workspaceId ??
                        workspaceSetting.workspaceId,
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class MobileFavoritePage extends StatelessWidget {
  const MobileFavoritePage({
    super.key,
    required this.userProfile,
    required this.workspaceId,
  });

  final UserProfilePB userProfile;
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
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
          child: MobileFavoritePageFolder(
            userProfile: userProfile,
            workspaceId: workspaceId,
          ),
        ),
      ],
    );
  }
}
