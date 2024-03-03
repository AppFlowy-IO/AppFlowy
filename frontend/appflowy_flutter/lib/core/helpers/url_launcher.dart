import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

typedef OnFailureCallback = void Function(Uri uri);

Future<bool> afLaunchUrl(
  Uri uri, {
  BuildContext? context,
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
    if (onFailure != null) {
      onFailure(uri);
    } else {
      showMessageToast(
        LocaleKeys.failedToOpenUrl.tr(args: [e.message ?? "PlatformException"]),
        context: context,
      );
    }
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
