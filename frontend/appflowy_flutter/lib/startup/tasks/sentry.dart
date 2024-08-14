import 'package:appflowy/env/env.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../startup.dart';

class InitSentryTask extends LaunchTask {
  const InitSentryTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    final dsn = Env.sentryDsn;
    if (dsn.isEmpty) {
      return;
    }
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 1.0;
        options.profilesSampleRate = 1.0;
      },
    );
  }

  @override
  Future<void> dispose() async {}
}
