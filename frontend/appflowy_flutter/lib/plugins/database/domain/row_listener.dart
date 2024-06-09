import 'dart:typed_data';

import 'package:appflowy/core/notification/grid_notification.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-error/protobuf.dart';
import 'package:appflowy_result/appflowy_result.dart';

typedef DidFetchRowCallback = void Function(DidFetchRowPB);
typedef RowMetaCallback = void Function(RowMetaPB);

class RowListener {
  RowListener(this.rowId);

  final String rowId;

  DidFetchRowCallback? _onRowFetchedCallback;
  RowMetaCallback? _onMetaChangedCallback;
  DatabaseNotificationListener? _listener;

  /// OnMetaChanged will be called when the row meta is changed.
  /// OnRowFetched will be called when the row is fetched from remote storage
  void start({
    RowMetaCallback? onMetaChanged,
    DidFetchRowCallback? onRowFetched,
  }) {
    _onMetaChangedCallback = onMetaChanged;
    _onRowFetchedCallback = onRowFetched;
    _listener = DatabaseNotificationListener(
      objectId: rowId,
      handler: _handler,
    );
  }

  void _handler(
    DatabaseNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case DatabaseNotification.DidUpdateRowMeta:
        result.fold(
          (payload) {
            if (_onMetaChangedCallback != null) {
              _onMetaChangedCallback!(RowMetaPB.fromBuffer(payload));
            }
          },
          (error) => Log.error(error),
        );
        break;
      case DatabaseNotification.DidFetchRow:
        result.fold(
          (payload) {
            if (_onRowFetchedCallback != null) {
              _onRowFetchedCallback!(DidFetchRowPB.fromBuffer(payload));
            }
          },
          (error) => Log.error(error),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    await _listener?.stop();
    _onMetaChangedCallback = null;
    _onRowFetchedCallback = null;
  }
}
