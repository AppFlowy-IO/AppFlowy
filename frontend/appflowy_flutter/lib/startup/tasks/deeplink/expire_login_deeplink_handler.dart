import 'dart:async';

import 'package:appflowy/startup/tasks/deeplink/deeplink_handler.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';

/// Expire login deeplink example:
/// appflowy-flutter:%23error=access_denied&error_code=403&error_description=Email+link+is+invalid+or+has+expired
class ExpireLoginDeepLinkHandler extends DeepLinkHandler<void> {
  @override
  bool canHandle(Uri uri) {
    final isExpireLogin = uri.toString().contains('error=access_denied');
    if (!isExpireLogin) {
      return false;
    }

    return true;
  }

  @override
  Future<FlowyResult<void, FlowyError>> handle({
    required Uri uri,
    required DeepLinkStateHandler onStateChange,
  }) async {
    return FlowyResult.failure(
      FlowyError(
        msg: 'Magic link is invalid or has expired',
      ),
    );
  }
}
