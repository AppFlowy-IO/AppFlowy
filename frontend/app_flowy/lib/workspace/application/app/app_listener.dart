import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/folder_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

typedef AppDidUpdateCallback = void Function(AppPB app);
typedef ViewsDidChangeCallback = void Function(
    Either<List<ViewPB>, FlowyError> viewsOrFailed);

class AppListener {
  StreamSubscription<SubscribeObject>? _subscription;
  AppDidUpdateCallback? _updated;
  FolderNotificationParser? _parser;
  String appId;

  AppListener({
    required this.appId,
  });

  void start({AppDidUpdateCallback? onAppUpdated}) {
    _updated = onAppUpdated;
    _parser = FolderNotificationParser(id: appId, callback: _handleCallback);
    _subscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  void _handleCallback(
      FolderNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case FolderNotification.AppUpdated:
        if (_updated != null) {
          result.fold(
            (payload) {
              final app = AppPB.fromBuffer(payload);
              _updated!(app);
            },
            (error) => Log.error(error),
          );
        }
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
    _updated = null;
  }
}
