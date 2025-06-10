import 'dart:async';

import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

class OpenAppDeepLinkHandler extends DeepLinkHandler<void> {
  @override
  bool canHandle(Uri uri) {
    return uri.toString() == 'appflowy-flutter://';
  }

  @override
  Future<FlowyResult<void, FlowyError>> handle({
    required Uri uri,
    required DeepLinkStateHandler onStateChange,
  }) async {
    return FlowyResult.success(null);
  }
}
