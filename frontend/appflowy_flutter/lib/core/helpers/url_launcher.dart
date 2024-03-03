import 'package:flutter/services.dart';

import 'package:appflowy_backend/log.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

typedef OnFailureCallback = void Function(Uri uri);

Future<bool> afLaunchUrl(
  Uri uri, {
  OnFailureCallback? onFailure,
  launcher.LaunchMode mode = launcher.LaunchMode.platformDefault,
  String? webOnlyWindowName,
}) async {
  try {
    return await launcher.launchUrl(
      uri,
      mode: mode,
      webOnlyWindowName: webOnlyWindowName,
    );
  } on PlatformException catch (e) {
    Log.error("Failed to open uri: $e");
    onFailure?.call(uri);
  }

  return false;
}

Future<void> afLaunchUrlString(String url) async {
  try {
    final uri = Uri.parse(url);

    await launcher.launchUrl(uri);
  } on PlatformException catch (e) {
    Log.error("Failed to open uri: $e");
  } on FormatException catch (e) {
    Log.error("Failed to parse url: $e");
  }
}
