import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:dartz/dartz.dart';

/// Listener for database layout changes.
class DatabaseLayoutListener {
  final String viewId;
  PublishNotifier<Either<DatabaseLayoutPB, FlowyError>>? _layoutNotifier =
      PublishNotifier();
  DatabaseNotificationListener? _listener;
  DatabaseLayoutListener(this.viewId);

  void start({
    required void Function(Either<DatabaseLayoutPB, FlowyError>)
        onLayoutChanged,
  }) {
    _layoutNotifier?.addPublishListener(onLayoutChanged);
    _listener = DatabaseNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(
    DatabaseNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateDatabaseLayout:
        result.fold(
          (payload) => _layoutNotifier?.value =
              left(DatabaseLayoutMetaPB.fromBuffer(payload).layout),
          (error) => _layoutNotifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _layoutNotifier?.dispose();
    _layoutNotifier = null;
  }
}
