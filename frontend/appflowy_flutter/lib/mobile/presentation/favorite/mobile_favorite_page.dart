import 'package:appflowy/mobile/presentation/favorite/mobile_favorite_folder.dart';
import 'package:appflowy/mobile/presentation/home/mobile_home_page_header.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/workspace/presentation/home/errors/workspace_failed_screen.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';

class MobileFavoriteScreen extends StatelessWidget {
  const MobileFavoriteScreen({
    super.key,
  });

  static const routeName = '/favorite';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([
        FolderEventGetCurrentWorkspace().send(),
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
        final userProfile =
            snapshots.data?[1].fold((error) => null, (userProfilePB) {
          return userProfilePB as UserProfilePB?;
        });

        // In the unlikely case either of the above is null, eg.
        // when a workspace is already open this can happen.
        if (workspaceSetting == null || userProfile == null) {
          return const WorkspaceFailedScreen();
        }

        return Scaffold(
          body: SafeArea(
            child: MobileFavoritePage(
              userProfile: userProfile,
              workspaceSetting: workspaceSetting,
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
    required this.workspaceSetting,
  });

  final UserProfilePB userProfile;
  final WorkspaceSettingPB workspaceSetting;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                padding: const EdgeInsets.all(8.0),
                child: MobileFavoritePageFolder(
                  userProfile: userProfile,
                  workspaceSetting: workspaceSetting,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
