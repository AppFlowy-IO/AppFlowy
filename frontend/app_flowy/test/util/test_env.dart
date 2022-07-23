import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/application/auth_service.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_sdk/protobuf/flowy-user/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FlowyTest {
  static Future<FlowyTest> setup() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // await EasyLocalization.ensureInitialized();

    await FlowyRunner.run(FlowyTestApp());
    return FlowyTest();
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
}

class FlowyTestApp implements EntryPoint {
  @override
  Widget create() {
    return Container();
  }
}
