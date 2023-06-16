import 'package:appflowy/startup/entry_point.dart';
import 'package:flutter/material.dart';

import 'startup/startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FlowyRunner.run(
    FlowyApp(),
    integrationEnv(),
  );
}
