import 'dart:async';
import 'dart:io';

import 'package:appflowy/ai/service/appflowy_ai_service.dart';
import 'package:appflowy/env/cloud_env.dart';
import 'package:appflowy/env/cloud_env_test.dart';
import 'package:appflowy/startup/entry_point.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/auth/af_cloud_mock_auth_service.dart';
import 'package:appflowy/user/application/auth/auth_service.dart';
import 'package:appflowy/user/presentation/presentation.dart';
import 'package:appflowy/user/presentation/screens/sign_in_screen/widgets/widgets.dart';
import 'package:appflowy/workspace/application/settings/prelude.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:universal_platform/universal_platform.dart';

import 'mock/mock_ai.dart';

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
    String? email,
    AuthenticatorType? cloudType,
    AIRepository Function()? aiRepositoryBuilder,
  }) async {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await binding.setSurfaceSize(windowSize);
    }
    //cloudType = AuthenticatorType.appflowyCloudDevelop;

    mockHotKeyManagerHandlers();
    final applicationDataDirectory = dataDirectory ??
        await mockApplicationDataStorage(
          pathExtension: pathExtension,
        );

    await FlowyRunner.run(
      AppFlowyApplication(),
      IntegrationMode.integrationTest,
      rustEnvsBuilder: () => _buildRustEnvs(cloudType),
      didInitGetItCallback: () => _initializeCloudServices(
        cloudType: cloudType,
        email: email,
        aiRepositoryBuilder: aiRepositoryBuilder,
      ),
    );

    await waitUntilSignInPageShow();
    return FlowyTestContext(
      applicationDataDirectory: applicationDataDirectory,
    );
  }

  Map<String, String> _buildRustEnvs(AuthenticatorType? cloudType) {
    final rustEnvs = <String, String>{};
    if (cloudType != null) {
      switch (cloudType) {
        case AuthenticatorType.local:
          break;
        case AuthenticatorType.appflowyCloudSelfHost:
        case AuthenticatorType.appflowyCloudDevelop:
          rustEnvs["GOTRUE_ADMIN_EMAIL"] = "admin@example.com";
          rustEnvs["GOTRUE_ADMIN_PASSWORD"] = "password";
          break;
        default:
          throw Exception("Unsupported cloud type: $cloudType");
      }
    }
    return rustEnvs;
  }

  Future<void> _initializeCloudServices({
    required AuthenticatorType? cloudType,
    String? email,
    AIRepository Function()? aiRepositoryBuilder,
  }) async {
    if (cloudType == null) return;

    switch (cloudType) {
      case AuthenticatorType.local:
        await useLocalServer();
        break;
      case AuthenticatorType.appflowyCloudSelfHost:
        await _setupAppFlowyCloud(
          useLocal: false,
          email: email,
          aiRepositoryBuilder: aiRepositoryBuilder,
        );
        break;
      case AuthenticatorType.appflowyCloudDevelop:
        await _setupAppFlowyCloud(
          useLocal: integrationMode().isDevelop,
          email: email,
          aiRepositoryBuilder: aiRepositoryBuilder,
        );
        break;
      default:
        throw Exception("Unsupported cloud type: $cloudType");
    }
  }

  Future<void> _setupAppFlowyCloud({
    required bool useLocal,
    String? email,
    AIRepository Function()? aiRepositoryBuilder,
  }) async {
    if (useLocal) {
      await useAppFlowyCloudDevelop("http://localhost");
    } else {
      await useSelfHostedAppFlowyCloud(TestEnv.afCloudUrl);
    }

    getIt.unregister<AuthService>();
    getIt.unregister<AIRepository>();

    getIt.registerFactory<AuthService>(
      () => AppFlowyCloudMockAuthService(email: email),
    );
    getIt.registerFactory<AIRepository>(
      aiRepositoryBuilder ?? () => MockAIRepository(),
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
    int buttons = kPrimaryButton,
    bool warnIfMissed = false,
    int milliseconds = 500,
    bool pumpAndSettle = true,
  }) async {
    await tap(finder, buttons: buttons, warnIfMissed: warnIfMissed);

    if (pumpAndSettle) {
      await this.pumpAndSettle(
        Duration(milliseconds: milliseconds),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
      );
    }
  }

  Future<void> tapDown(
    Finder finder, {
    int? pointer,
    int buttons = kPrimaryButton,
    PointerDeviceKind kind = PointerDeviceKind.touch,
    bool pumpAndSettle = true,
    int milliseconds = 500,
  }) async {
    final location = getCenter(finder);
    final TestGesture gesture = await startGesture(
      location,
      pointer: pointer,
      buttons: buttons,
      kind: kind,
    );
    await gesture.cancel();
    await gesture.down(location);
    await gesture.cancel();
    if (pumpAndSettle) {
      await this.pumpAndSettle(
        Duration(milliseconds: milliseconds),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 15),
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

  Future<void> slideToValue(
    Finder slider,
    double value, {
    double paddingOffset = 24.0,
  }) async {
    final sliderWidget = slider.evaluate().first.widget as Slider;
    final range = sliderWidget.max - sliderWidget.min;
    final initialRate = (value - sliderWidget.min) / range;
    final totalWidth = getSize(slider).width - (2 * paddingOffset);
    final zeroPoint = getTopLeft(slider) +
        Offset(
          paddingOffset + initialRate * totalWidth,
          getSize(slider).height / 2,
        );
    final calculatedOffset = value * (totalWidth / 100);
    await dragFrom(zeroPoint, Offset(calculatedOffset, 0));
    await pumpAndSettle();
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
