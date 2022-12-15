import 'dart:io';

import 'package:app_flowy/main.dart' as app;
import 'package:app_flowy/startup/tasks/prelude.dart';
import 'package:app_flowy/workspace/application/settings/settings_location_cubit.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

extension AppFlowyTestBase on WidgetTester {
  /// Clean the location.
  Future<void> cleanLocation(String path) async {
    await Directory(path).delete(
      recursive: true,
    );
    return;
  }

  Future<String> currentLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(kSettingsLocationDefaultLocation)!;
  }

  Future<String> defaultLocation() async {
    final dir = await appFlowyDocumentDirectory();
    return dir.path;
  }

  Future<void> initializeAppFlowy() async {
    const MethodChannel('hotkey_manager')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'unregisterAll') {
        // do nothing
      }
    });
    await app.main();
    await pumpAndSettle();
  }

  /// Set a given AppFlowy data storage location.
  ///
  /// To pass null means clear the location.
  ///
  /// The file_picker is a system component and can't be tapped, so using logic instead of tapping.
  ///
  Future<void> setLocation(String? path) async {
    SharedPreferences.setMockInitialValues({
      kSettingsLocationDefaultLocation: path ?? '',
    });
    return;
  }

  Future<void> tapButton(
    Finder finder, {
    int? pointer,
    int buttons = kPrimaryButton,
    bool warnIfMissed = true,
    int milliseconds = 500,
  }) async {
    await tap(finder);
    await wait(milliseconds);
    return;
  }

  Future<void> wait(int milliseconds) async {
    await pumpAndSettle(Duration(milliseconds: milliseconds));
    return;
  }
}
