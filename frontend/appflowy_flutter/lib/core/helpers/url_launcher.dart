import 'dart:io';

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
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;

typedef OnFailureCallback = void Function(Uri uri);

/// Launch the uri
///
/// If the uri is a local file path, it will be opened with the OpenFilex.
/// Otherwise, it will be launched with the url_launcher.
Future<bool> afLaunchUri(
  Uri uri, {
  BuildContext? context,
  OnFailureCallback? onFailure,
  launcher.LaunchMode mode = launcher.LaunchMode.platformDefault,
  String? webOnlyWindowName,
  bool addingHttpSchemeWhenFailed = false,
}) async {
  final url = uri.toString();
  final decodedUrl = Uri.decodeComponent(url);

  // check if the uri is the local file path
  if (localPathRegex.hasMatch(decodedUrl)) {
    return _afLaunchLocalUri(
      uri,
      context: context,
      onFailure: onFailure,
    );
  }

  // on Linux, add http scheme to the url if it is not present
  if (UniversalPlatform.isLinux && !isURL(url, {'require_protocol': true})) {
    uri = Uri.parse('https://$url');
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

/// Launch the url string
///
/// See [afLaunchUri] for more details.
Future<bool> afLaunchUrlString(
  String url, {
  bool addingHttpSchemeWhenFailed = false,
  BuildContext? context,
  OnFailureCallback? onFailure,
}) async {
  final Uri uri;
  try {
    uri = Uri.parse(url);
  } on FormatException catch (e) {
    Log.error('Failed to parse url: $e');
    return false;
  }

  // try to launch the uri directly
  return afLaunchUri(
    uri,
    addingHttpSchemeWhenFailed: addingHttpSchemeWhenFailed,
    context: context,
    onFailure: onFailure,
  );
}

/// Launch the local uri
///
/// See [afLaunchUri] for more details.
Future<bool> _afLaunchLocalUri(
  Uri uri, {
  BuildContext? context,
  OnFailureCallback? onFailure,
}) async {
  final decodedUrl = Uri.decodeComponent(uri.toString());
  // open the file with the OpenfileX
  var result = await OpenFilex.open(decodedUrl);
  if (result.type != ResultType.done) {
    // For the file cant be opened, fallback to open the folder
    final parentFolder = Directory(decodedUrl).parent.path;
    result = await OpenFilex.open(parentFolder);
  }
  // show the toast if the file is not found
  final message = switch (result.type) {
    ResultType.done => LocaleKeys.openFileMessage_success.tr(),
    ResultType.fileNotFound => LocaleKeys.openFileMessage_fileNotFound.tr(),
    ResultType.noAppToOpen => LocaleKeys.openFileMessage_noAppToOpenFile.tr(),
    ResultType.permissionDenied =>
      LocaleKeys.openFileMessage_permissionDenied.tr(),
    ResultType.error => LocaleKeys.failedToOpenUrl.tr(),
  };
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
