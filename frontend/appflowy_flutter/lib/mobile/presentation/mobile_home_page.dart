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
          return const Center(child: CircularProgressIndicator());
        }

        WorkspaceSettingPB? workspaceSetting;
        UserProfilePB? userProfile;
        snapshots.data?[0].fold(
          (workspaceSettingPB) {
            workspaceSetting = workspaceSettingPB as WorkspaceSettingPB?;
          },
          (error) => null,
        );
        snapshots.data?[1].fold((error) => null, (userProfilePB) {
          userProfile = userProfilePB as UserProfilePB?;
        });

        return Scaffold(
          key: ValueKey(userProfile?.id),
          appBar: AppBar(
            title: const Text("MobileHomeScreen"),
          ),
          // TODO(yijing): implement home page later
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
