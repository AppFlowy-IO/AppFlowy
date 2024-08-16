import 'package:appflowy/env/env.dart';
import 'package:appflowy_backend/log.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../startup.dart';

class InitSentryTask extends LaunchTask {
  const InitSentryTask();

  @override
  Future<void> initialize(LaunchContext context) async {
    const dsn = Env.sentryDsn;
    if (dsn.isEmpty) {
      Log.info('Sentry DSN is not set, skipping initialization');
      return;
    }

    Log.info('Initializing Sentry');

    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = 0.1;
        options.profilesSampleRate = 0.1;
      },
    );
  }

  @override
  Future<void> dispose() async {}
}
