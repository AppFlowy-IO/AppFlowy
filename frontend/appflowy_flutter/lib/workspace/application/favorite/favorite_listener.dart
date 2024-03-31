import 'dart:async';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter/foundation.dart';

typedef FavoriteUpdated = void Function(
  FlowyResult<RepeatedViewPB, FlowyError> result,
  bool isFavorite,
);

class FavoriteListener {
  StreamSubscription<SubscribeObject>? _streamSubscription;
  FolderNotificationParser? _parser;

  FavoriteUpdated? _favoriteUpdated;

  void start({
    FavoriteUpdated? favoritesUpdated,
  }) {
    _favoriteUpdated = favoritesUpdated;
    _parser = FolderNotificationParser(
      id: 'favorite',
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
    switch (ty) {
      case FolderNotification.DidFavoriteView:
        result.onSuccess(
          (success) => _favoriteUpdated?.call(
            FlowyResult.success(RepeatedViewPB.fromBuffer(success)),
            true,
          ),
        );
      case FolderNotification.DidUnfavoriteView:
        result.map(
          (success) => _favoriteUpdated?.call(
            FlowyResult.success(RepeatedViewPB.fromBuffer(success)),
            false,
          ),
        );
        break;
      default:
        break;
    }
  }

  Future<void> stop() async {
    _parser = null;
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _favoriteUpdated = null;
  }
}
