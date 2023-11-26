import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:dartz/dartz.dart';

import '../../../core/notification/user_notification.dart';

class UserCloudConfigListener {
  StreamSubscription<SubscribeObject>? _subscription;
  void Function(Either<CloudSettingPB, FlowyError>)? _onSettingChanged;

  UserNotificationParser? _userParser;
  UserCloudConfigListener();

  void start({
    void Function(Either<CloudSettingPB, FlowyError>)? onSettingChanged,
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
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case UserNotification.DidUpdateCloudConfig:
        result.fold(
          (payload) =>
              _onSettingChanged?.call(left(CloudSettingPB.fromBuffer(payload))),
          (error) => _onSettingChanged?.call(right(error)),
        );
        break;
      default:
        break;
    }
  }
}
