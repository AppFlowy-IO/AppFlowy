import 'dart:io';

import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FlowyTestContext {
  FlowyTestContext({
    required this.applicationDataDirectory,
  });

  final String applicationDataDirectory;
}

extension AppFlowyTestBase on WidgetTester {
  Future<FlowyTestContext> initializeAppFlowy({
    // use to append after the application data directory
    String? pathExtension,
    Size windowsSize = const Size(1600, 1200),
  }) async {
    binding.setSurfaceSize(windowsSize);

    mockHotKeyManagerHandlers();
    final directory = await mockApplicationDataStorage(
      pathExtension: pathExtension,
    );

    WidgetsFlutterBinding.ensureInitialized();
    await FlowyRunner.run(
      FlowyApp(),
      IntegrationMode.integrationTest,
    );

    await wait(3000);
    await pumpAndSettle(const Duration(seconds: 2));
    return FlowyTestContext(
      applicationDataDirectory: directory,
    );
  }

  void mockHotKeyManagerHandlers() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('hotkey_manager'),
            (MethodCall methodCall) async {
      if (methodCall.method == 'unregisterAll') {
        // do nothing
      }
      return;
    });
  }

  Future<String> mockApplicationDataStorage({
    // use to append after the application data directory
    String? pathExtension,
  }) async {
    final dir = await getTemporaryDirectory();

    // Use a random uuid to avoid conflict.
    String path = p.join(dir.path, 'appflowy_integration_test', uuid());
    if (pathExtension != null && pathExtension.isNotEmpty) {
      path = '$path/$pathExtension';
    }
    final directory = Directory(path);
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }

    MockApplicationDataStorage.initialPath = directory.path;

    return directory.path;
  }

  Future<void> tapButton(
    Finder finder, {
    int? pointer,
    int buttons = kPrimaryButton,
    bool warnIfMissed = false,
    int milliseconds = 500,
  }) async {
    await tap(
      finder,
      buttons: buttons,
      warnIfMissed: warnIfMissed,
    );
    await pumpAndSettle(Duration(milliseconds: milliseconds));
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

  Future<void> doubleTapAt(
    Offset location, {
    int? pointer,
    int buttons = kPrimaryButton,
    int milliseconds = 500,
  }) async {
    await tapAt(location, pointer: pointer, buttons: buttons);
    await pump(kDoubleTapMinTime);
    await tapAt(location, pointer: pointer, buttons: buttons);
    await pumpAndSettle(Duration(milliseconds: milliseconds));
  }

  Future<void> doubleTapButton(
    Finder finder, {
    int? pointer,
    int buttons = kPrimaryButton,
    bool warnIfMissed = true,
    int milliseconds = 500,
  }) async {
    await tap(
      finder,
      pointer: pointer,
      buttons: buttons,
      warnIfMissed: warnIfMissed,
    );

    await pump(kDoubleTapMinTime);

    await tap(
      finder,
      buttons: buttons,
      pointer: pointer,
      warnIfMissed: warnIfMissed,
    );
    await pumpAndSettle(Duration(milliseconds: milliseconds));
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
