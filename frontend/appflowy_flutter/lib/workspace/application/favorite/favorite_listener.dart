import 'dart:async';

import 'package:appflowy/core/notification/folder_notification.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/favorite.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/notification.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-notification/subject.pb.dart';
import 'package:appflowy_backend/rust_stream.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

class FavoriteListener {
  StreamSubscription<SubscribeObject>? _streamSubscription;
  void Function(Either<FlowyError, List<ViewPB>>)? _favoriteUpdated;
  FolderNotificationParser? _parser;

  void start({
    void Function(Either<FlowyError, List<ViewPB>>)? favoritesUpdated,
  }) {
    _favoriteUpdated = favoritesUpdated;
    _parser = FolderNotificationParser(
      id: "favorite",
      callback: _observableCallback,
    );
    _streamSubscription =
        RustStreamReceiver.listen((observable) => _parser?.parse(observable));
  }

  void _observableCallback(
      FolderNotification ty, Either<Uint8List, FlowyError> result) {
    Log.warn(ty);
    switch (ty) {
      // case FolderNotification.DidToggleFavorite:
      // break;
      case FolderNotification.FavoritesUpdated:
        if (_favoriteUpdated != null) {
          result.fold(
            (payload) {
              final repeatedFavorites = RepeatedViewPB.fromBuffer(payload);
              _favoriteUpdated!(right(repeatedFavorites.items));
            },
            (error) => _favoriteUpdated!(left(error)),
          );
        }
        break;
      default:
        break;
    }
  }
}
