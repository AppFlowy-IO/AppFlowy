import 'dart:io';

import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/startup/tasks/prelude.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  static Future<Directory> setTestLocation(String? name) async {
    final location = await testLocation(name);
    SharedPreferences.setMockInitialValues({
      KVKeys.pathLocation: location.path,
    });
    return location;
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
    final dir = await appFlowyApplicationDataDirectory();
    return dir.path;
  }

  /// Get default location under test environment.
  static Future<Directory> testLocation(String? name) async {
    final dir = await getTemporaryDirectory();
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
        .setMockMethodCallHandler(const MethodChannel('hotkey_manager'),
            (MethodCall methodCall) async {
      if (methodCall.method == 'unregisterAll') {
        // do nothing
      }

      return;
    });

    WidgetsFlutterBinding.ensureInitialized();
    await FlowyRunner.run(FlowyApp(), IntegrationMode.integrationTest);

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
    await tap(
      finder,
      buttons: buttons,
      warnIfMissed: warnIfMissed,
    );
    await pumpAndSettle(Duration(milliseconds: milliseconds));
    return;
  }

  Future<void> tapButtonWithName(
    String tr, {
    int milliseconds = 500,
  }) async {
    Finder button = find.text(
      tr,
      findRichText: true,
      skipOffstage: false,
    );
    if (button.evaluate().isEmpty) {
      button = find.byWidgetPredicate(
        (widget) => widget is FlowyText && widget.text == tr,
      );
    }
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

  Future<void> doubleTapButton(
    Finder finder, {
    int? pointer,
    int buttons = kPrimaryButton,
    bool warnIfMissed = true,
    int milliseconds = 500,
  }) async {
    await tapButton(
      finder,
      pointer: pointer,
      buttons: buttons,
      warnIfMissed: warnIfMissed,
      milliseconds: kDoubleTapMinTime.inMilliseconds,
    );
    await tapButton(
      finder,
      pointer: pointer,
      buttons: buttons,
      warnIfMissed: warnIfMissed,
      milliseconds: milliseconds,
    );
  }

  Future<void> wait(int milliseconds) async {
    await pumpAndSettle(Duration(milliseconds: milliseconds));
    return;
  }
}

extension AppFlowyFinderTestBase on CommonFinders {
  Finder findTextInFlowyText(String text) {
    return find.byWidgetPredicate(
      (widget) => widget is FlowyText && widget.text == text,
    );
  }
}
