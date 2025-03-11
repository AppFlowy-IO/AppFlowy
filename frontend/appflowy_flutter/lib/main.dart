import 'package:appflowy/generated/rust_bridge/frb_generated.dart';
import 'package:scaled_app/scaled_app.dart';

import 'startup/startup.dart';

Future<void> main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (_) => 1.0,
  );

  // TODO(Lucas): Move it the task
  await RustLib.init();

  await runAppFlowy();
}
