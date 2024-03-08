import 'package:appflowy/workspace/application/favorite/favorite_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'favorite_listener.dart';

part 'favorite_bloc.freezed.dart';

class FavoriteBloc extends Bloc<FavoriteEvent, FavoriteState> {
  FavoriteBloc() : super(FavoriteState.initial()) {
    _dispatch();
  }

  final _service = FavoriteService();
  final _listener = FavoriteListener();

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _dispatch() {
    on<FavoriteEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            _listener.start(
              favoritesUpdated: _onFavoritesUpdated,
            );
            final result = await _service.readFavorites();
            emit(
              result.fold(
                (view) => state.copyWith(
                  views: view.items,
                ),
                (error) => state.copyWith(
                  views: [],
                ),
              ),
            );
          },
          didFavorite: (e) {
            emit(
              state.copyWith(views: [...state.views, ...e.favorite.items]),
            );
          },
          didUnfavorite: (e) {
            final views = [...state.views]..removeWhere(
                (view) => e.favorite.items.any((item) => item.id == view.id),
              );
            emit(
              state.copyWith(views: views),
            );
          },
          toggle: (e) async {
            await _service.toggleFavorite(
              e.view.id,
              !e.view.isFavorite,
            );
          },
        );
      },
    );
  }

  void _onFavoritesUpdated(
    FlowyResult<RepeatedViewPB, FlowyError> favoriteOrFailed,
    bool didFavorite,
  ) {
    favoriteOrFailed.fold(
      (favorite) => didFavorite
          ? add(FavoriteEvent.didFavorite(favorite))
          : add(FavoriteEvent.didUnfavorite(favorite)),
      (error) => Log.error(error),
    );
  }
}

@freezed
class FavoriteEvent with _$FavoriteEvent {
  const factory FavoriteEvent.initial() = Initial;
  const factory FavoriteEvent.didFavorite(RepeatedViewPB favorite) =
      DidFavorite;
  const factory FavoriteEvent.didUnfavorite(RepeatedViewPB favorite) =
      DidUnfavorite;
  const factory FavoriteEvent.toggle(ViewPB view) = ToggleFavorite;
}

@freezed
class FavoriteState with _$FavoriteState {
  const factory FavoriteState({
    required List<ViewPB> views,
  }) = _FavoriteState;

  factory FavoriteState.initial() => const FavoriteState(
        views: [],
      );
}
