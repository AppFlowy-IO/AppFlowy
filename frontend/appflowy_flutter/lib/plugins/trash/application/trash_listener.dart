import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/trash.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';

typedef TrashUpdatedCallback = void Function(
  Either<List<TrashPB>, FlowyError> trashOrFailed,
);

class TrashListener {
  StreamSubscription<SubscribeObject>? _subscription;
  TrashUpdatedCallback? _trashUpdated;
  FolderNotificationParser? _parser;

  void start({TrashUpdatedCallback? trashUpdated}) {
    _trashUpdated = trashUpdated;
    _parser = FolderNotificationParser(
      id: "trash",
      callback: _observableCallback,
    );
    _subscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  void _observableCallback(
    FolderNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case FolderNotification.DidUpdateTrash:
        if (_trashUpdated != null) {
          result.fold(
            (payload) {
              final repeatedTrash = RepeatedTrashPB.fromBuffer(payload);
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
