import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/patterns/common_patterns.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
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
    Log.info('Launch local uri: $decodedUrl');
    return _afLaunchLocalUri(
      uri,
      context: context,
      onFailure: onFailure,
    );
  }

  // on Linux, add http scheme to the url if it is not present
  if (UniversalPlatform.isLinux && !isURL(url, {'require_protocol': true})) {
    Log.info('Add http scheme to the url on Linux: $url');
    uri = Uri.parse('https://$url');
  }

  // try to launch the uri directly
  bool result = await launcher.canLaunchUrl(uri);
  Log.info('Can launch uri: $result');
  if (result) {
    try {
      Log.info('Try to launch uri: $uri');
      result = await launcher.launchUrl(
        uri,
        mode: mode,
        webOnlyWindowName: webOnlyWindowName,
      );
    } catch (e) {
      Log.error('Failed to open uri: $e');
      return false;
    }
  }

  // if the uri is not a valid url, try to launch it with http scheme

  if (addingHttpSchemeWhenFailed &&
      !result &&
      !isURL(url, {'require_protocol': true})) {
    try {
      Log.info('Try to add http scheme to the url: $url');
      // add http scheme to the url
      // if the url is not a valid url, add http scheme to the url
      // and try to launch it again
      final uriWithScheme = Uri.parse('http://$url');
      result = await launcher.launchUrl(
        uriWithScheme,
        mode: mode,
        webOnlyWindowName: webOnlyWindowName,
      );
    } catch (error) {
      Log.error('Failed to open uri (platform exception): $error');
      if (context != null && context.mounted) {
        _errorHandler(
          uri,
          context: context,
          onFailure: onFailure,
          error: error,
        );
      }
      return false;
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
  } catch (e) {
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
  Object? error,
}) {
  Log.error('Failed to open uri: $error');

  if (onFailure != null) {
    onFailure(uri);
  } else {
    showMessageToast(
      LocaleKeys.failedToOpenUrl
          .tr(args: [error?.toString() ?? "PlatformException"]),
      context: context,
    );
  }
}
