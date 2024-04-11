import 'dart:async';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/foundation.dart';

typedef RecentViewsUpdated = void Function(
  FlowyResult<RepeatedViewIdPB, FlowyError> result,
);

class RecentViewsListener {
  StreamSubscription<SubscribeObject>? _streamSubscription;
  FolderNotificationParser? _parser;

  RecentViewsUpdated? _recentViewsUpdated;

  void start({
    RecentViewsUpdated? recentViewsUpdated,
  }) {
    _recentViewsUpdated = recentViewsUpdated;
    _parser = FolderNotificationParser(
      id: 'recent_views',
      callback: _observableCallback,
    );
    _streamSubscription = RustStreamReceiver.listen(
      (observable) => _parser?.parse(observable),
    );
  }

  void _observableCallback(
    FolderNotification ty,
    FlowyResult<Uint8List, FlowyError> result,
  ) {
    if (_recentViewsUpdated == null) {
      return;
    }

    result.fold(
      (payload) {
        final view = RepeatedViewIdPB.fromBuffer(payload);
        _recentViewsUpdated?.call(
          FlowyResult.success(view),
        );
      },
      (error) => _recentViewsUpdated?.call(
        FlowyResult.failure(error),
      ),
    );
  }

  Future<void> stop() async {
    _parser = null;
    await _streamSubscription?.cancel();
    _recentViewsUpdated = null;
  }
}
