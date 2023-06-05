import 'dart:async';
import 'dart:typed_data';
import 'package:appflowy/core/folder_notification.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:flowy_infra/notifier.dart';

// Delete the view from trash, which means the view was deleted permanently
typedef DeleteViewNotifyValue = Either<ViewPB, FlowyError>;
// The view get updated
typedef UpdateViewNotifiedValue = Either<ViewPB, FlowyError>;
// Restore the view from trash
typedef RestoreViewNotifiedValue = Either<ViewPB, FlowyError>;
// Move the view to trash
typedef MoveToTrashNotifiedValue = Either<DeletedViewPB, FlowyError>;

class ViewListener {
  StreamSubscription<SubscribeObject>? _subscription;
  final _updatedViewNotifier = PublishNotifier<UpdateViewNotifiedValue>();
  final _deletedNotifier = PublishNotifier<DeleteViewNotifyValue>();
  final _restoredNotifier = PublishNotifier<RestoreViewNotifiedValue>();
  final _moveToTrashNotifier = PublishNotifier<MoveToTrashNotifiedValue>();
  FolderNotificationParser? _parser;
  ViewPB view;

  ViewListener({
    required this.view,
  });

  void start({
    final void Function(UpdateViewNotifiedValue)? onViewUpdated,
    final void Function(DeleteViewNotifyValue)? onViewDeleted,
    final void Function(RestoreViewNotifiedValue)? onViewRestored,
    final void Function(MoveToTrashNotifiedValue)? onViewMoveToTrash,
  }) {
    if (onViewUpdated != null) {
      _updatedViewNotifier.addListener(() {
        onViewUpdated(_updatedViewNotifier.currentValue!);
      });
    }

    if (onViewDeleted != null) {
      _deletedNotifier.addListener(() {
        onViewDeleted(_deletedNotifier.currentValue!);
      });
    }

    if (onViewRestored != null) {
      _restoredNotifier.addListener(() {
        onViewRestored(_restoredNotifier.currentValue!);
      });
    }

    if (onViewMoveToTrash != null) {
      _moveToTrashNotifier.addListener(() {
        onViewMoveToTrash(_moveToTrashNotifier.currentValue!);
      });
    }

    _parser = FolderNotificationParser(
      id: view.id,
      callback: (final ty, final result) {
        _handleObservableType(ty, result);
      },
    );

    _subscription =
        RustStreamReceiver.listen((final observable) => _parser?.parse(observable));
  }

  void _handleObservableType(
    final FolderNotification ty,
    final Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case FolderNotification.DidUpdateView:
        result.fold(
          (final payload) =>
              _updatedViewNotifier.value = left(ViewPB.fromBuffer(payload)),
          (final error) => _updatedViewNotifier.value = right(error),
        );
        break;
      case FolderNotification.DidDeleteView:
        result.fold(
          (final payload) =>
              _deletedNotifier.value = left(ViewPB.fromBuffer(payload)),
          (final error) => _deletedNotifier.value = right(error),
        );
        break;
      case FolderNotification.DidRestoreView:
        result.fold(
          (final payload) =>
              _restoredNotifier.value = left(ViewPB.fromBuffer(payload)),
          (final error) => _restoredNotifier.value = right(error),
        );
        break;
      case FolderNotification.DidMoveViewToTrash:
        result.fold(
          (final payload) => _moveToTrashNotifier.value =
              left(DeletedViewPB.fromBuffer(payload)),
          (final error) => _moveToTrashNotifier.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    _parser = null;
    await _subscription?.cancel();
    _updatedViewNotifier.dispose();
    _deletedNotifier.dispose();
    _restoredNotifier.dispose();
  }
}
