import 'package:appflowy/startup/launch_configuration.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppFlowyUnitTest {
  late UserProfilePB userProfile;
  late UserBackendService userService;
  late WorkspaceService workspaceService;
  late WorkspacePB workspace;

  static Future<AppFlowyUnitTest> ensureInitialized() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    _pathProviderInitialized();

    await FlowyRunner.run(
      AppFlowyApplicationUniTest(),
      IntegrationMode.unitTest,
    );

    final test = AppFlowyUnitTest();
    await test._signIn();
    await test._loadWorkspace();

    await test._initialServices();
    return test;
  }

  Future<void> _signIn() async {
    final authService = getIt<AuthService>();
    const password = "AppFlowy123@";
    final uid = uuid();
    final userEmail = "$uid@appflowy.io";
    final result = await authService.signUp(
      name: "TestUser",
      password: password,
      email: userEmail,
    );
    result.fold(
      (user) {
        userProfile = user;
        userService = UserBackendService(userId: userProfile.id);
      },
      (error) {
        assert(false, 'Error: $error');
      },
    );
  }

  WorkspacePB get currentWorkspace => workspace;

  Future<void> _loadWorkspace() async {
    final result = await userService.getCurrentWorkspace();
    result.fold(
      (value) => workspace = value,
      (error) {
        throw Exception(error);
      },
    );
  }

  Future<void> _initialServices() async {
    workspaceService = WorkspaceService(workspaceId: currentWorkspace.id);
  }

  Future<ViewPB> createWorkspace() async {
    final result = await workspaceService.createView(
      name: "Test App",
      viewSection: ViewSectionPB.Public,
    );
    return result.fold(
      (app) => app,
      (error) => throw Exception(error),
    );
  }

  Future<List<ViewPB>> loadApps() async {
    final result = await workspaceService.getPublicViews();

    return result.fold(
      (apps) => apps,
      (error) => throw Exception(error),
    );
  }
}

void _pathProviderInitialized() {
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/path_provider');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    return '.';
  });
}

class AppFlowyApplicationUniTest implements EntryPoint {
  @override
  Widget create(LaunchConfiguration config) {
    return const SizedBox.shrink();
  }
}

Future<void> blocResponseFuture({int millisecond = 200}) {
  return Future.delayed(Duration(milliseconds: millisecond));
}

Duration blocResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
