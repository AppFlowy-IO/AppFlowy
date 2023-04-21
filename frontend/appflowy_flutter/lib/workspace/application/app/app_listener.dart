import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy/core/folder_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/notification.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';

typedef AppDidUpdateCallback = void Function(ViewPB app);
typedef ViewsDidChangeCallback = void Function(
  Either<List<ViewPB>, FlowyError> viewsOrFailed,
);

class AppListener {
  StreamSubscription<SubscribeObject>? _subscription;
  AppDidUpdateCallback? _updated;
  FolderNotificationParser? _parser;
  String viewId;

  AppListener({
    required this.viewId,
  });

  void start({AppDidUpdateCallback? onAppUpdated}) {
    _updated = onAppUpdated;
    _parser = FolderNotificationParser(id: viewId, callback: _handleCallback);
    _subscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  void _handleCallback(
    FolderNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case FolderNotification.DidUpdateView:
      case FolderNotification.DidUpdateChildViews:
        if (_updated != null) {
          result.fold(
            (payload) {
              final app = ViewPB.fromBuffer(payload);
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
