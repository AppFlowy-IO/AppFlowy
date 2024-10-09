import 'package:scaled_app/scaled_app.dart';

import 'startup/startup.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized with a constant scale factor
  ScaledWidgetsFlutterBinding.ensureInitialized(scaleFactor: (_) => 1.0);

  await runAppFlowy();
}
