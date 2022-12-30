import 'dart:typed_data';

import 'package:app_flowy/core/grid_notification.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/sort_entities.pb.dart';

typedef SortNotifiedValue = Either<SortChangesetNotificationPB, FlowyError>;

class SortsListener {
  final String viewId;
  PublishNotifier<SortNotifiedValue>? _notifier = PublishNotifier();
  GridNotificationListener? _listener;

  SortsListener({required this.viewId});

  void start({
    required void Function(SortNotifiedValue) onSortChanged,
  }) {
    _notifier?.addPublishListener(onSortChanged);
    _listener = GridNotificationListener(
      objectId: viewId,
      handler: _handler,
    );
  }

  void _handler(
    GridDartNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case GridDartNotification.DidUpdateSort:
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
