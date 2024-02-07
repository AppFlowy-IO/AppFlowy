import 'dart:async';
import 'dart:typed_data';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:dartz/dartz.dart';

// parent view of overview block updated
typedef ParentViewUpdateNotifier = void Function(ViewPB);

typedef ChildViewsUpdateNotifier = void Function(ChildViewUpdatePB);

class WorkspaceOverviewListener {
  WorkspaceOverviewListener({
    required this.viewId,
  });

  final String viewId;

  FolderNotificationParser? _parser;
  StreamSubscription<SubscribeObject>? _subscription;
  ParentViewUpdateNotifier? _parentViewUpdateNotifier;
  ChildViewsUpdateNotifier? _childViewsUpdateNotifier;

  bool _isDisposed = false;

  void start({
    ParentViewUpdateNotifier? onParentViewUpdated,
    ChildViewsUpdateNotifier? onChildViewsUpdated,
  }) {
    if (_isDisposed) {
      Log.warn("Workspace Overview Listener is already disposed");
      return;
    }

    _parentViewUpdateNotifier = onParentViewUpdated;
    _childViewsUpdateNotifier = onChildViewsUpdated;

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
      case FolderNotification.DidUpdateWorkspaceOverviewParentView:
        result.fold(
          (payload) {
            final view = ViewPB.fromBuffer(payload);
            _parentViewUpdateNotifier?.call(view);
          },
          (err) => Log.error(err),
        );
        break;
      case FolderNotification.DidUpdateWorkspaceOverviewChildViews:
        result.fold(
          (payload) {
            final childview = ChildViewUpdatePB.fromBuffer(payload);
            _childViewsUpdateNotifier?.call(childview);
          },
          (err) => Log.error(err),
        );
        break;
      default:
        break;
    }
  }

  /// Registers an overview block listener Id in the backend, allowing us to receive
  /// notifications of [FolderNotification.DidUpdateWorkspaceOverviewChildViews] from
  /// all levels of child views to the specified parent view Id listener.
  static Future<Either<Unit, FlowyError>> addListenerId(String viewId) {
    final payload = ViewIdPB.create()..value = viewId;
    return FolderEventRegisterWorkspaceOverviewListenerId(payload).send();
  }

  static Future<Either<Unit, FlowyError>> removeListener(String viewId) {
    final payload = ViewIdPB.create()..value = viewId;
    return FolderEventRemoveWorkspaceOverviewListenerId(payload).send();
  }

  Future<void> stop() async {
    _isDisposed = false;
    _parser = null;
    await _subscription?.cancel();
    _subscription = null;
    _parentViewUpdateNotifier = _childViewsUpdateNotifier = null;
  }
}
