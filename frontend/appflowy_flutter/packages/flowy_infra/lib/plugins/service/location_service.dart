import 'dart:io';

import 'package:path_provider/path_provider.dart';

class PluginLocationService {
  static Future<Directory> get fallback async =>
      await getApplicationDocumentsDirectory();

  static Future<Directory> get location async => fallback;
}
