import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/user/infrastructure/repos/auth_repo.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_sdk/protobuf/flowy-user-data-model/protobuf.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FlowyTest {
  static Future<FlowyTest> setup() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // await EasyLocalization.ensureInitialized();

    await FlowySystem.run(FlowyTestApp());
    return FlowyTest();
  }

  Future<UserProfile> signIn() async {
    final authRepo = getIt<AuthRepository>();
    const password = "AppFlowy123@";
    final uid = uuid();
    final userEmail = "$uid@appflowy.io";
    final result = await authRepo.signUp(
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
