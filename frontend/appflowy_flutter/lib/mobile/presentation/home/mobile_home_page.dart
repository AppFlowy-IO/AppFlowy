import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';

// TODO(yijing): This is just a placeholder for now.
class MobileHomeScreen extends StatelessWidget {
  const MobileHomeScreen({super.key});

  static const routeName = "/MobileHomeScreen";

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
        // TODO(yijing): implement home page later
        return Scaffold(
          key: ValueKey(userProfile?.id),
          // TODO(yijing):Need to change to workspace when it is ready
          appBar: AppBar(
            title: Text(
              userProfile?.email.toString() ?? 'No email found',
            ),
            actions: [
              IconButton(
                onPressed: () {
                  // TODO(yijing): Navigate to setting page
                },
                icon: const FlowySvg(
                  FlowySvgs.m_setting_m,
                ),
              )
            ],
          ),
          body: Center(
            child: Column(
              children: [
                const Text(
                  'User',
                ),
                Text(
                  userProfile.toString(),
                ),
                Text('Workspace name: ${workspaceSetting?.workspace.name}'),
                ElevatedButton(
                  onPressed: () async {
                    await getIt<AuthService>().signOut();
                    runAppFlowy();
                  },
                  child: const Text('Logout'),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
