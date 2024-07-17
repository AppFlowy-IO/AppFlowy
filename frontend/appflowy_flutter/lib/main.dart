import 'package:scaled_app/scaled_app.dart';

import 'startup/startup.dart';

Future<void> main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized(scaleFactor: (_) => 1.0);

  await runAppFlowy();

  // trigger the ci
}
