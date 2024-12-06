import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:open_filex/open_filex.dart';
import 'package:string_validator/string_validator.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

typedef OnFailureCallback = void Function(Uri uri);

Future<bool> afLaunchUrl(
  Uri uri, {
  BuildContext? context,
  OnFailureCallback? onFailure,
  launcher.LaunchMode mode = launcher.LaunchMode.platformDefault,
  String? webOnlyWindowName,
  bool addingHttpSchemeWhenFailed = false,
}) async {
  final url = uri.toString();

  // check if the uri is the local file path
  if (localPathRegex.hasMatch(url)) {
    // open the file with the OpenfileX
    final result = await OpenFilex.open(url);
    // show the toast if the file is not found
    String message = '';
    switch (result.type) {
      case ResultType.done:
        message = LocaleKeys.openFileMessage_success.tr();
      case ResultType.fileNotFound:
        message = LocaleKeys.openFileMessage_fileNotFound.tr();
      case ResultType.noAppToOpen:
        message = LocaleKeys.openFileMessage_noAppToOpenFile.tr();
      case ResultType.permissionDenied:
        message = LocaleKeys.openFileMessage_permissionDenied.tr();
      case ResultType.error:
        message = LocaleKeys.failedToOpenUrl.tr();
    }
    if (context != null && context.mounted) {
      showToastNotification(
        context,
        message: message,
        type: result.type == ResultType.done
            ? ToastificationType.success
            : ToastificationType.error,
      );
    }
    final openFileSuccess = result.type == ResultType.done;
    if (!openFileSuccess && onFailure != null) {
      onFailure(uri);
      Log.error('Failed to open file: $result.message');
    }
    return openFileSuccess;
  }

  // try to launch the uri directly
  bool result;
  try {
    result = await launcher.launchUrl(
      uri,
      mode: mode,
      webOnlyWindowName: webOnlyWindowName,
    );
  } on PlatformException catch (e) {
    Log.error('Failed to open uri: $e');
    return false;
  }

  // if the uri is not a valid url, try to launch it with http scheme

  if (addingHttpSchemeWhenFailed &&
      !result &&
      !isURL(url, {'require_protocol': true})) {
    try {
      final uriWithScheme = Uri.parse('http://$url');
      result = await launcher.launchUrl(
        uriWithScheme,
        mode: mode,
        webOnlyWindowName: webOnlyWindowName,
      );
    } on PlatformException catch (e) {
      Log.error('Failed to open uri: $e');
      if (context != null && context.mounted) {
        _errorHandler(uri, context: context, onFailure: onFailure, e: e);
      }
    }
  }

  return result;
}

Future<bool> afLaunchUrlString(
  String url, {
  bool addingHttpSchemeWhenFailed = false,
}) async {
  final Uri uri;
  try {
    uri = Uri.parse(url);
  } on FormatException catch (e) {
    Log.error('Failed to parse url: $e');
    return false;
  }

  // try to launch the uri directly
  return afLaunchUrl(
    uri,
    addingHttpSchemeWhenFailed: addingHttpSchemeWhenFailed,
  );
}

void _errorHandler(
  Uri uri, {
  BuildContext? context,
  OnFailureCallback? onFailure,
  PlatformException? e,
}) {
  Log.error('Failed to open uri: $e');

  if (onFailure != null) {
    onFailure(uri);
  } else {
    showMessageToast(
      LocaleKeys.failedToOpenUrl.tr(args: [e?.message ?? "PlatformException"]),
      context: context,
    );
  }
}
