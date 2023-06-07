import 'dart:io';

import 'package:path_provider/path_provider.dart';

// TODO(a-wallen): allow registering multiple directories.
/// A service that provides the location of the plugins.
class PluginLocationService {
  static Future<Directory> get fallback async =>
      await getApplicationDocumentsDirectory();

  static Future<Directory> get location async => fallback;
}
