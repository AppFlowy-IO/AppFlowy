import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';

class MobileHomePage extends StatelessWidget {
  const MobileHomePage(
    this.user,
    this.workspaceSetting, {
    super.key,
  });
  static const routeName = "/MobileHomePage";
  final UserProfilePB user;
  final WorkspaceSettingPB workspaceSetting;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MobileHomePage"),
      ),
      // TODO(yijing): implement home page later
      body: Center(
        child: Column(
          children: [
            const Text(
              'User',
            ),
            Text(
              user.toString(),
            ),
            Text('Workspace name: ${workspaceSetting.workspace.name}'),
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
  }
}
