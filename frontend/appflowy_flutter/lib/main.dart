import 'package:flutter/material.dart';
import 'package:scaled_app/scaled_app.dart';

import 'startup/startup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (_) => 1.0,
  );

  await runAppFlowy();
}
