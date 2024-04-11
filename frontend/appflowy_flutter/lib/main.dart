import 'package:flutter/material.dart';

import 'startup/startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await runAppFlowy();
}
