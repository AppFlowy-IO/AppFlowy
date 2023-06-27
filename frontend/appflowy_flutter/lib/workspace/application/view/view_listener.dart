import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy_backend/log.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/notification.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';

// Delete the view from trash, which means the view was deleted permanently
typedef DeleteViewNotifyValue = Either<ViewPB, FlowyError>;
// The view get updated
typedef UpdateViewNotifiedValue = ViewPB;
// Restore the view from trash
typedef RestoreViewNotifiedValue = Either<ViewPB, FlowyError>;
// Move the view to trash
typedef MoveToTrashNotifiedValue = Either<DeletedViewPB, FlowyError>;

class ViewListener {
  StreamSubscription<SubscribeObject>? _subscription;
  void Function(UpdateViewNotifiedValue)? _updatedViewNotifier;
  void Function(ChildViewUpdatePB)? _updateViewChildViewsNotifier;
  void Function(DeleteViewNotifyValue)? _deletedNotifier;
  void Function(RestoreViewNotifiedValue)? _restoredNotifier;
  void Function(MoveToTrashNotifiedValue)? _moveToTrashNotifier;
  bool _isDisposed = false;

  FolderNotificationParser? _parser;
  final String viewId;

  ViewListener({
    required this.viewId,
  });

  void start({
    void Function(UpdateViewNotifiedValue)? onViewUpdated,
    void Function(ChildViewUpdatePB)? onViewChildViewsUpdated,
    void Function(DeleteViewNotifyValue)? onViewDeleted,
    void Function(RestoreViewNotifiedValue)? onViewRestored,
    void Function(MoveToTrashNotifiedValue)? onViewMoveToTrash,
  }) {
    if (_isDisposed) {
      Log.warn("ViewListener is already disposed");
      return;
    }

    _updatedViewNotifier = onViewUpdated;
    _deletedNotifier = onViewDeleted;
    _restoredNotifier = onViewRestored;
    _moveToTrashNotifier = onViewMoveToTrash;
    _updateViewChildViewsNotifier = onViewChildViewsUpdated;

    _parser = FolderNotificationParser(
      id: viewId,
      callback: (ty, result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  void _handleObservableType(
    FolderNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case FolderNotification.DidUpdateView:
        result.fold(
          (payload) {
            final view = ViewPB.fromBuffer(payload);
            _updatedViewNotifier?.call(view);
          },
          (error) => Log.error(error),
        );
        break;
      case FolderNotification.DidUpdateChildViews:
        result.fold(
          (payload) {
            final pb = ChildViewUpdatePB.fromBuffer(payload);
            _updateViewChildViewsNotifier?.call(pb);
          },
          (error) => Log.error(error),
        );
        break;
      case FolderNotification.DidDeleteView:
        result.fold(
          (payload) => _deletedNotifier?.call(left(ViewPB.fromBuffer(payload))),
          (error) => _deletedNotifier?.call(right(error)),
        );
        break;
      case FolderNotification.DidRestoreView:
        result.fold(
          (payload) =>
              _restoredNotifier?.call(left(ViewPB.fromBuffer(payload))),
          (error) => _restoredNotifier?.call(right(error)),
        );
        break;
      case FolderNotification.DidMoveViewToTrash:
        result.fold(
          (payload) => _moveToTrashNotifier
              ?.call(left(DeletedViewPB.fromBuffer(payload))),
          (error) => _moveToTrashNotifier?.call(right(error)),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    _isDisposed = true;
    _parser = null;
    await _subscription?.cancel();
    _updatedViewNotifier = null;
    _deletedNotifier = null;
    _restoredNotifier = null;
  }
}
