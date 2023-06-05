import 'dart:io';

import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/main.dart' as app;
import 'package:appflowy/startup/tasks/prelude.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestFolder {
  /// Location / Path

  /// Set a given AppFlowy data storage location under test environment.
  ///
  /// To pass null means clear the location.
  ///
  /// The file_picker is a system component and can't be tapped, so using logic instead of tapping.
  ///
  static Future<void> setTestLocation(String? name) async {
    final location = await testLocation(name);
    SharedPreferences.setMockInitialValues({
      KVKeys.pathLocation: location.path,
    });
    return;
  }

  /// Clean the location.
  static Future<void> cleanTestLocation(String? name) async {
    final dir = await testLocation(name);
    await dir.delete(recursive: true);
    return;
  }

  /// Get current using location.
  static Future<String> currentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(KVKeys.pathLocation)!;
  }

  /// Get default location under development environment.
  static Future<String> defaultDevelopmentLocation() async {
    final dir = await appFlowyDocumentDirectory();
    return dir.path;
  }

  /// Get default location under test environment.
  static Future<Directory> testLocation(String? name) async {
    final dir = await getApplicationDocumentsDirectory();
    var path = '${dir.path}/flowy_test';
    if (name != null) {
      path += '/$name';
    }
    return Directory(path).create(recursive: true);
  }
}

extension AppFlowyTestBase on WidgetTester {
  Future<void> initializeAppFlowy() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('hotkey_manager'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'unregisterAll') {
          // do nothing
        }

        return;
      },
    );

    await app.main();
    await wait(3000);
    await pumpAndSettle(const Duration(seconds: 2));
  }

  Future<void> tapButton(
    Finder finder, {
    int? pointer,
    int buttons = kPrimaryButton,
    bool warnIfMissed = true,
    int milliseconds = 500,
  }) async {
    await tap(finder);
    await pumpAndSettle(Duration(milliseconds: milliseconds));
    return;
  }

  Future<void> tapButtonWithName(
    String tr, {
    int milliseconds = 500,
  }) async {
    final button = find.text(tr, findRichText: true);
    await tapButton(
      button,
      milliseconds: milliseconds,
    );
    return;
  }

  Future<void> tapButtonWithTooltip(
    String tr, {
    int milliseconds = 500,
  }) async {
    final button = find.byTooltip(tr);
    await tapButton(
      button,
      milliseconds: milliseconds,
    );
    return;
  }

  Future<void> wait(int milliseconds) async {
    await pumpAndSettle(Duration(milliseconds: milliseconds));
    return;
  }
}
