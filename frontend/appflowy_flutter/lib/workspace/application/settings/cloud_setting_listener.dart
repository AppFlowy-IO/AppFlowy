import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';

import '../../../core/notification/user_notification.dart';

class UserCloudConfigListener {
  UserCloudConfigListener();

  UserNotificationParser? _userParser;
  StreamSubscription<SubscribeObject>? _subscription;
  void Function(FlowyResult<CloudSettingPB, FlowyError>)? _onSettingChanged;

  void start({
    void Function(FlowyResult<CloudSettingPB, FlowyError>)? onSettingChanged,
  }) {
    _onSettingChanged = onSettingChanged;
    _userParser = UserNotificationParser(
      id: 'user_cloud_config',
      callback: _userNotificationCallback,
    );
    _subscription = RustStreamReceiver.listen((observable) {
      _userParser?.parse(observable);
    });
  }

  Future<void> stop() async {
    _userParser = null;
    await _subscription?.cancel();
    _onSettingChanged = null;
  }

  void _userNotificationCallback(
    UserNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case UserNotification.DidUpdateCloudConfig:
        result.fold(
          (payload) => _onSettingChanged
              ?.call(FlowyResult.success(CloudSettingPB.fromBuffer(payload))),
          (error) => _onSettingChanged?.call(FlowyResult.failure(error)),
        );
        break;
      default:
        break;
    }
  }
}
