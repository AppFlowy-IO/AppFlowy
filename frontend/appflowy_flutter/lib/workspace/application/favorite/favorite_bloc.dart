import 'package:appflowy/workspace/application/favorite/favorite_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/favorite.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'favorite_listener.dart';

part 'favorite_bloc.freezed.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  final FavoriteService _service;
  final FavoriteListener _listener;
  FavoriteBloc()
      : _service = FavoriteService(),
        _listener = FavoriteListener(),
        super(FavoriteState.initial()) {
    on<FavoriteEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            _listener.start(
              favoritesUpdated: _listenFavoritesUpdated,
            );
            final result = await _service.readFavorites();
            Log.warn("read favorites $result");
            emit(
              result.fold(
                (object) => state.copyWith(
                  objects: object.items,
                  successOrFailure: left(unit),
                ),
                (error) => state.copyWith(
                  successOrFailure: right(error),
                ),
              ),
            );
          },
          didReceiveFavorite: (e) {
            Log.warn(e.favorite);
            emit(state.copyWith(objects: e.favorite));
          },
          toggle: (e) async {
            final result = await _service.toggleFavorite(e.viewId);
            emit(
              result.fold(
                (l) => state.copyWith(successOrFailure: left(unit)),
                (error) => state.copyWith(successOrFailure: right(error)),
              ),
            );
          },
        );
      },
    );
  }
  void _listenFavoritesUpdated(
    Either<List<FavoritesPB>, FlowyError> favoriteOrFailed,
  ) {
    favoriteOrFailed.fold(
      (favorite) {
        add(FavoriteEvent.didReceiveFavorite(favorite));
      },
      (error) => Log.error(error),
    );
  }
}

@freezed
class FavoriteEvent with _$FavoriteEvent {
  const factory FavoriteEvent.initial() = Initial;
  const factory FavoriteEvent.didReceiveFavorite(List<FavoritesPB> favorite) =
      ReceiveFavorites;
  const factory FavoriteEvent.toggle(String viewId) = ToggleFavorite;
}

@freezed
class FavoriteState with _$FavoriteState {
  const factory FavoriteState({
    required List<FavoritesPB> objects,
    required Either<Unit, FlowyError> successOrFailure,
  }) = _FavoriteState;

  factory FavoriteState.initial() => FavoriteState(
        objects: [],
        successOrFailure: left(unit),
      );
}
