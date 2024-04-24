import 'package:flutter/material.dart';

import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';

import 'startup/startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  VideoBlockKit.ensureInitialized();

  await runAppFlowy();
}
