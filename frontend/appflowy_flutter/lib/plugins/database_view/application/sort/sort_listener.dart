import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/sort_entities.pb.dart';

typedef SortNotifiedValue = Either<SortChangesetNotificationPB, FlowyError>;

class SortsListener {
  final String viewId;
  PublishNotifier<SortNotifiedValue>? _notifier = PublishNotifier();
  DatabaseNotificationListener? _listener;

  SortsListener({required this.viewId});

  void start({
    required void Function(SortNotifiedValue) onSortChanged,
  }) {
    _notifier?.addPublishListener(onSortChanged);
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
      case DatabaseNotification.DidUpdateSort:
        result.fold(
          (payload) => _notifier?.value =
              left(SortChangesetNotificationPB.fromBuffer(payload)),
          (error) => _notifier?.value = right(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _notifier?.dispose();
    _notifier = null;
  }
}
