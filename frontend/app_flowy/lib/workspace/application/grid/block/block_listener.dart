import 'dart:async';
import 'dart:typed_data';

import 'package:app_flowy/core/notification_helper.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/block_entities.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';

typedef GridBlockUpdateNotifierValue = Either<List<GridRowsChangeset>, FlowyError>;

class GridBlockListener {
  final String blockId;
  PublishNotifier<GridBlockUpdateNotifierValue>? _rowsUpdateNotifier = PublishNotifier();
  GridNotificationListener? _listener;

  GridBlockListener({required this.blockId});

  void start(void Function(GridBlockUpdateNotifierValue) onBlockChanged) {
    if (_listener != null) {
      _listener?.stop();
    }

    _listener = GridNotificationListener(
      objectId: blockId,
      handler: _handler,
    );

    _rowsUpdateNotifier?.addPublishListener(onBlockChanged);
  }

  void _handler(GridNotification ty, Either<Uint8List, FlowyError> result) {
    switch (ty) {
      case GridNotification.DidUpdateGridBlock:
        result.fold(
          (payload) => _rowsUpdateNotifier?.value = left([GridRowsChangeset.fromBuffer(payload)]),
          (error) => _rowsUpdateNotifier?.value = right(error),
        );
        break;

      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _rowsUpdateNotifier?.dispose();
    _rowsUpdateNotifier = null;
  }
}
