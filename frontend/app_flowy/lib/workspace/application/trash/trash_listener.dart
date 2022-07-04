import 'dart:async';
import 'dart:typed_data';
import 'package:app_flowy/core/folder_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/dart-notify/subject.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/dart_notification.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/trash.pb.dart';
import 'package:flowy_sdk/rust_stream.dart';

typedef TrashUpdatedCallback = void Function(Either<List<Trash>, FlowyError> trashOrFailed);

class TrashListener {
  StreamSubscription<SubscribeObject>? _subscription;
  TrashUpdatedCallback? _trashUpdated;
  FolderNotificationParser? _parser;

  void start({TrashUpdatedCallback? trashUpdated}) {
    _trashUpdated = trashUpdated;
    _parser = FolderNotificationParser(callback: _bservableCallback);
    _subscription = RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  void _bservableCallback(FolderNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case FolderNotification.TrashUpdated:
        if (_trashUpdated != null) {
          result.fold(
            (payload) {
              final repeatedTrash = RepeatedTrash.fromBuffer(payload);
              _trashUpdated!(left(repeatedTrash.items));
            },
            (error) => _trashUpdated!(right(error)),
          );
        }
        break;
      default:
        break;
    }
  }

  Future<void> close() async {
    _parser = null;
    await _subscription?.cancel();
    _trashUpdated = null;
  }
}
