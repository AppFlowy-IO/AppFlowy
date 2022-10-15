import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:app_flowy/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppFlowyIntegrateTest {
  static Future<AppFlowyIntegrateTest> ensureInitialized() async {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    main();
    return AppFlowyIntegrateTest();
  }
}

class AppFlowyBlocTest {
  static Future<AppFlowyBlocTest> ensureInitialized() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    pathProviderInitialized();

    await EasyLocalization.ensureInitialized();
    await FlowyRunner.run(FlowyTestApp());
    return AppFlowyBlocTest();
  }
}

void pathProviderInitialized() {
  const MethodChannel channel =
      MethodChannel('plugins.flutter.io/path_provider');
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    return ".";
  });
}

Future<UserProfilePB> signIn() async {
  final authService = getIt<AuthService>();
  const password = "AppFlowy123@";
  final uid = uuid();
  final userEmail = "$uid@appflowy.io";
  final result = await authService.signUp(
    name: "FlowyTestUser",
    password: password,
    email: userEmail,
  );
  return result.fold(
    (user) => user,
    (error) {
      throw StateError("$error");
    },
  );
}

class FlowyTestApp implements EntryPoint {
  @override
  Widget create() {
    return Container();
  }
}
