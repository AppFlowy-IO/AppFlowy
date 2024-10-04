import 'dart:async';
import 'dart:io';

import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/env/cloud_env_test.dart';
import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/presentation.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';

class FlowyTestContext {
  FlowyTestContext({required this.applicationDataDirectory});

  final String applicationDataDirectory;
}

extension AppFlowyTestBase on WidgetTester {
  Future<FlowyTestContext> initializeAppFlowy({
    // use to append after the application data directory
    String? pathExtension,
    // use to specify the application data directory, if not specified, a temporary directory will be used.
    String? dataDirectory,
    Size windowSize = const Size(1600, 1200),
    AuthenticatorType? cloudType,
    String? email,
  }) async {
    if (UniversalPlatform.isDesktop) {
      // Set the window size
      await binding.setSurfaceSize(windowSize);
    }

    if (UniversalPlatform.isMobile) {
      // Disable the log in test for mobile
      Log.shared.disableLogInTest = true;
    }

    mockHotKeyManagerHandlers();
    final applicationDataDirectory = dataDirectory ??
        await mockApplicationDataStorage(
          pathExtension: pathExtension,
        );

    await FlowyRunner.run(
      AppFlowyApplication(),
      IntegrationMode.integrationTest,
      rustEnvsBuilder: () {
        final rustEnvs = <String, String>{};
        if (cloudType != null) {
          switch (cloudType) {
            case AuthenticatorType.local:
              break;
            case AuthenticatorType.appflowyCloudSelfHost:
              rustEnvs["GOTRUE_ADMIN_EMAIL"] = "admin@example.com";
              rustEnvs["GOTRUE_ADMIN_PASSWORD"] = "password";
              break;
            default:
              throw Exception("not supported");
          }
        }
        return rustEnvs;
      },
      didInitGetItCallback: () {
        return Future(
          () async {
            if (cloudType != null) {
              switch (cloudType) {
                case AuthenticatorType.local:
                  await useLocalServer();
                  break;
                case AuthenticatorType.appflowyCloudSelfHost:
                  await useTestSelfHostedAppFlowyCloud();
                  getIt.unregister<AuthService>();
                  getIt.registerFactory<AuthService>(
                    () => AppFlowyCloudMockAuthService(email: email),
                  );
                default:
                  throw Exception("not supported");
              }
            }
          },
        );
      },
    );

    await waitUntilSignInPageShow();
    return FlowyTestContext(
      applicationDataDirectory: applicationDataDirectory,
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

  Future<void> waitUntilSignInPageShow() async {
    // mobile platform doesn't support non-auth mode
    if (isAuthEnabled || UniversalPlatform.isMobile) {
      final finder = find.byType(SignInAnonymousButtonV2);
      await pumpUntilFound(finder, timeout: const Duration(seconds: 30));
      expect(finder, findsOneWidget);
    } else {
      final finder = find.byType(GoButton);
      await pumpUntilFound(finder);
      expect(finder, findsOneWidget);
    }
  }

  Future<void> waitForSeconds(int seconds) async {
    await Future.delayed(Duration(seconds: seconds), () {});
  }

  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration pumpInterval = const Duration(
      milliseconds: 50,
    ), // Interval between pumps
  }) async {
    bool timerDone = false;
    final timer = Timer(timeout, () => timerDone = true);
    while (!timerDone) {
      await pump(pumpInterval); // Pump with an interval
      if (any(finder)) {
        break;
      }
    }
    timer.cancel();
  }

  Future<void> pumpUntilNotFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 10),
    Duration pumpInterval = const Duration(
      milliseconds: 50,
    ), // Interval between pumps
  }) async {
    bool timerDone = false;
    final timer = Timer(timeout, () => timerDone = true);
    while (!timerDone) {
      await pump(pumpInterval); // Pump with an interval
      if (!any(finder)) {
        break;
      }
    }
    timer.cancel();
  }

  Future<void> tapButton(
    Finder finder, {
    int? pointer,
    int buttons = kPrimaryButton,
    bool warnIfMissed = false,
    int milliseconds = 500,
    bool pumpAndSettle = true,
  }) async {
    await tap(
      finder,
      buttons: buttons,
      warnIfMissed: warnIfMissed,
    );

    if (pumpAndSettle) {
      await this.pumpAndSettle(
        Duration(milliseconds: milliseconds),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
    }
  }

  Future<void> tapButtonWithName(
    String tr, {
    int milliseconds = 500,
    bool pumpAndSettle = true,
  }) async {
    Finder button = find.text(tr, findRichText: true, skipOffstage: false);
    if (button.evaluate().isEmpty) {
      button = find.byWidgetPredicate(
        (widget) => widget is FlowyText && widget.text == tr,
      );
    }
    await tapButton(
      button,
      milliseconds: milliseconds,
      pumpAndSettle: pumpAndSettle,
    );
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

  Future<void> wait(int milliseconds) async {
    await pumpAndSettle(Duration(milliseconds: milliseconds));
  }
}

extension AppFlowyFinderTestBase on CommonFinders {
  Finder findTextInFlowyText(String text) {
    return find.byWidgetPredicate(
      (widget) => widget is FlowyText && widget.text == text,
    );
  }

  Finder findFlowyTooltip(String richMessage, {bool skipOffstage = true}) {
    return byWidgetPredicate(
      (widget) =>
          widget is FlowyTooltip &&
          widget.richMessage != null &&
          widget.richMessage!.toPlainText().contains(richMessage),
      skipOffstage: skipOffstage,
    );
  }
}

Future<void> useTestSelfHostedAppFlowyCloud() async {
  await useSelfHostedAppFlowyCloudWithURL(TestEnv.afCloudUrl);
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
