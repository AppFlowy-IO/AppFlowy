import 'dart:async';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

typedef FavoriteUpdated = void Function(
  Either<FlowyError, RepeatedViewPB> result,
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
    Either<Uint8List, FlowyError> result,
  ) {
    if (_favoriteUpdated == null) {
      return;
    }

    final isFavorite = ty == FolderNotification.DidFavoriteView;
    result.fold(
      (payload) {
        final view = RepeatedViewPB.fromBuffer(payload);
        _favoriteUpdated!(
          right(view),
          isFavorite,
        );
      },
      (error) => _favoriteUpdated!(
        left(error),
        isFavorite,
      ),
    );
  }

  Future<void> stop() async {
    _parser = null;
    await _streamSubscription?.cancel();
    _streamSubscription = null;
    _favoriteUpdated = null;
  }
}
