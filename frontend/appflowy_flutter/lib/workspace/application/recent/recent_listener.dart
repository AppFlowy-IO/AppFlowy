import 'dart:async';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

typedef RecentViewsUpdated = void Function(
  Either<FlowyError, RepeatedViewIdPB> result,
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
    Either<Uint8List, FlowyError> result,
  ) {
    if (_recentViewsUpdated == null) {
      return;
    }

    result.fold(
      (payload) {
        final view = RepeatedViewIdPB.fromBuffer(payload);
        _recentViewsUpdated?.call(
          right(view),
        );
      },
      (error) => _recentViewsUpdated?.call(
        left(error),
      ),
    );
  }

  Future<void> stop() async {
    _parser = null;
    await _streamSubscription?.cancel();
    _recentViewsUpdated = null;
  }
}
