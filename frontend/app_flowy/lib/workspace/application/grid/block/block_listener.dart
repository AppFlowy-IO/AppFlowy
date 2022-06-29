import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:app_flowy/core/notification_helper.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/dart_notification.pb.dart';

class GridBlockCache {
  final String gridId;
  void Function(GridBlockUpdateNotifierValue)? _onBlockChanged;

  final LinkedHashMap<String, _GridBlockListener> _listeners = LinkedHashMap();
  GridBlockCache({required this.gridId});

  void start(void Function(GridBlockUpdateNotifierValue) onBlockChanged) {
    _onBlockChanged = onBlockChanged;
    for (final listener in _listeners.values) {
      listener.start(onBlockChanged);
    }
  }

  Future<void> dispose() async {
    for (final listener in _listeners.values) {
      await listener.stop();
    }
  }

  void addBlockListener(String blockId) {
    if (_onBlockChanged == null) {
      Log.error("Should call start() first");
      return;
    }
    if (_listeners.containsKey(blockId)) {
      Log.error("Duplicate block listener");
      return;
    }

    final listener = _GridBlockListener(blockId: blockId);
    listener.start(_onBlockChanged!);
    _listeners[blockId] = listener;
  }
}

typedef GridBlockUpdateNotifierValue = Either<List<GridRowsChangeset>, FlowyError>;

class _GridBlockListener {
  final String blockId;
  PublishNotifier<GridBlockUpdateNotifierValue>? _rowsUpdateNotifier = PublishNotifier();
  GridNotificationListener? _listener;

  _GridBlockListener({required this.blockId});

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
