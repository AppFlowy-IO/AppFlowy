import 'package:appflowy/src/rust/frb_generated.dart';
import 'package:scaled_app/scaled_app.dart';

import 'startup/startup.dart';

Future<void> main() async {
  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (_) => 1.0,
  );

  // TODO(Lucas): move it to task queue
  await RustLib.init();

  await runAppFlowy();
}
