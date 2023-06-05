import 'package:appflowy/startup/launch_configuration.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth_service.dart';
import 'package:appflowy/user/application/user_service.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
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

    await EasyLocalization.ensureInitialized();
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
    return result.fold(
      (final user) {
        userProfile = user;
        userService = UserBackendService(userId: userProfile.id);
      },
      (final error) {},
    );
  }

  WorkspacePB get currentWorkspace => workspaces[0];

  Future<void> _loadWorkspace() async {
    final result = await userService.getWorkspaces();
    result.fold(
      (final value) => workspaces = value,
      (final error) {
        throw Exception(error);
      },
    );
  }

  Future<void> _initialServices() async {
    workspaceService = WorkspaceService(workspaceId: currentWorkspace.id);
  }

  Future<AppPB> createTestApp() async {
    final result = await workspaceService.createApp(name: "Test App");
    return result.fold(
      (final app) => app,
      (final error) => throw Exception(error),
    );
  }

  Future<List<AppPB>> loadApps() async {
    final result = await workspaceService.getApps();

    return result.fold(
      (final apps) => apps,
      (final error) => throw Exception(error),
    );
  }
}

void _pathProviderInitialized() {
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/path_provider');
  channel.setMockMethodCallHandler((final MethodCall methodCall) async {
    return ".";
  });
}

class FlowyTestApp implements EntryPoint {
  @override
  Widget create(final LaunchConfiguration config) {
    return Container();
  }
}

Future<void> blocResponseFuture({final int millisecond = 200}) {
  return Future.delayed(Duration(milliseconds: millisecond));
}

Duration blocResponseDuration({final int milliseconds = 200}) {
  return Duration(milliseconds: milliseconds);
}
