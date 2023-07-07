import 'package:appflowy/workspace/application/favorite/favorite_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/favorite.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
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
            emit(
              result.fold(
                (object) => state.copyWith(
                  objects: object.items,
                  successOrFailure: right(unit),
                ),
                (error) => state.copyWith(
                  successOrFailure: left(error),
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
                (l) => state.copyWith(successOrFailure: right(unit)),
                (error) => state.copyWith(successOrFailure: left(error)),
              ),
            );
          },
        );
      },
    );
  }
  void _listenFavoritesUpdated(
    Either<FlowyError, List<ViewPB>> favoriteOrFailed,
  ) {
    favoriteOrFailed.fold(
      (error) => Log.error(error),
      (favorite) => add(
        FavoriteEvent.didReceiveFavorite(favorite),
      ),
    );
  }
}

@freezed
class FavoriteEvent with _$FavoriteEvent {
  const factory FavoriteEvent.initial() = Initial;
  const factory FavoriteEvent.didReceiveFavorite(List<ViewPB> favorite) =
      ReceiveFavorites;
  const factory FavoriteEvent.toggle(String viewId) = ToggleFavorite;
}

@freezed
class FavoriteState with _$FavoriteState {
  const factory FavoriteState({
    required List<ViewPB> objects,
    required Either<FlowyError, Unit> successOrFailure,
  }) = _FavoriteState;

  factory FavoriteState.initial() => FavoriteState(
        objects: [],
        successOrFailure: right(unit),
      );
}
