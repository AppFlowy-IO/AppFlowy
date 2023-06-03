import 'package:appflowy/startup/launch_configuration.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:appflowy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppFlowyIntegrateTest {
  static Future<AppFlowyIntegrateTest> ensureInitialized() async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    main();
    return AppFlowyIntegrateTest();
  }
}

class AppFlowyUnitTest {
  late UserProfilePB userProfile;
  late UserBackendService userService;
  late WorkspaceService workspaceService;
  late List<WorkspacePB> workspaces;

  static Future<AppFlowyUnitTest> ensureInitialized() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    _pathProviderInitialized();

    await FlowyRunner.run(FlowyTestApp());

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
      (error) {
        assert(false, 'Error: $error');
      },
      (user) {
        userProfile = user;
        userService = UserBackendService(userId: userProfile.id);
      },
    );
  }

  WorkspacePB get currentWorkspace => workspaces[0];

  Future<void> _loadWorkspace() async {
    final result = await userService.getWorkspaces();
    result.fold(
      (value) => workspaces = value,
      (error) {
        throw Exception(error);
      },
    );
  }

  Future<void> _initialServices() async {
    workspaceService = WorkspaceService(workspaceId: currentWorkspace.id);
  }

  Future<ViewPB> createTestApp() async {
    final result = await workspaceService.createApp(name: "Test App");
    return result.fold(
      (app) => app,
      (error) => throw Exception(error),
    );
  }

  Future<List<ViewPB>> loadApps() async {
    final result = await workspaceService.getViews();

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

class FlowyTestApp implements EntryPoint {
  @override
  Widget create(LaunchConfiguration config) {
    return Container();
  }
}

Future<void> blocResponseFuture({int millisecond = 200}) {
  return Future.delayed(Duration(milliseconds: millisecond));
}

Duration blocResponseDuration({int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
