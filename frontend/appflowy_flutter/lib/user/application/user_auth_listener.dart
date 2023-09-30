import 'dart:async';
import 'package:appflowy/core/notification/user_notification.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/auth.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'dart:typed_data';
import 'package:appflowy_backend/protobuf/flowy-notification/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-user/notification.pb.dart'
    as user;
import 'package:appflowy_backend/rust_stream.dart';

class UserAuthStateListener {
  void Function(String)? _onForceLogout;
  void Function()? _didSignIn;
  StreamSubscription<SubscribeObject>? _subscription;
  UserNotificationParser? _userParser;

  void start({
    void Function(String)? onForceLogout,
    void Function()? didSignIn,
  }) {
    _onForceLogout = onForceLogout;
    _didSignIn = didSignIn;

    _userParser = UserNotificationParser(
      id: "auth_state_change_notification",
      callback: _userNotificationCallback,
    );
    _subscription = RustStreamReceiver.listen((observable) {
      _userParser?.parse(observable);
    });
  }

  Future<void> stop() async {
    _userParser = null;
    await _subscription?.cancel();
    _onForceLogout = null;
  }

  void _userNotificationCallback(
    user.UserNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case user.UserNotification.UserAuthStateChanged:
        result.fold(
          (payload) {
            final pb = AuthStateChangedPB.fromBuffer(payload);
            switch (pb.state) {
              case AuthStatePB.AuthStateSignIn:
                _didSignIn?.call();
                break;
              case AuthStatePB.AuthStateForceSignOut:
                _onForceLogout?.call("");
                break;
              default:
                break;
            }
          },
          (r) => Log.error(r),
        );
        break;
      default:
        break;
    }
  }
}
