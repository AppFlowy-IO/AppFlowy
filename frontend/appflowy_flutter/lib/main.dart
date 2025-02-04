import 'package:auto_updater/auto_updater.dart';
import 'package:scaled_app/scaled_app.dart';

import 'startup/startup.dart';

Future<void> main() async {
  // WidgetsFlutterBinding.ensureInitialized();

  ScaledWidgetsFlutterBinding.ensureInitialized(
    scaleFactor: (_) => 1.0,
  );

  const String feedURL = 'http://localhost:5002/appcast.xml';
  await autoUpdater.setFeedURL(feedURL);
  await autoUpdater.checkForUpdates();
  await autoUpdater.setScheduledCheckInterval(3600);

  await runAppFlowy();
}
