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
  void Function(Either<FlowyError, ViewPB>, bool)? _favoriteUpdated;
  FolderNotificationParser? _parser;

  void start({
    void Function(Either<FlowyError, ViewPB>, bool)? favoritesUpdated,
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
    FolderNotification ty,
    Either<Uint8List, FlowyError> result,
  ) {
    switch (ty) {
      case FolderNotification.DidFavoriteView:
        if (_favoriteUpdated != null) {
          result.fold(
            (payload) {
              final favoriteView = ViewPB.fromBuffer(payload);
              _favoriteUpdated!(right(favoriteView), true);
            },
            (error) => _favoriteUpdated!(left(error), true),
          );
        }
        break;
      case FolderNotification.DidUnFavoriteView:
        if (_favoriteUpdated != null) {
          result.fold(
            (payload) {
              final unfavoriteView = ViewPB.fromBuffer(payload);
              _favoriteUpdated!(right(unfavoriteView), false);
            },
            (error) => _favoriteUpdated!(left(error), false),
          );
        }
        break;
      // case FolderNotification.FavoritesUpdated:
      //   if (_favoriteUpdated != null) {
      //     result.fold(
      //       (payload) {
      //         final repeatedFavorites = RepeatedViewPB.fromBuffer(payload);
      //         _favoriteUpdated!(right(repeatedFavorites.items));
      //       },
      //       (error) => _favoriteUpdated!(left(error)),
      //     );
      //   }
      //   break;
      default:
        break;
    }
  }
}
