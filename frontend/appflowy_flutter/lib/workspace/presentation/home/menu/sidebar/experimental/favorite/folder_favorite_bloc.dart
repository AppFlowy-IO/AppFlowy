import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_favorite_bloc.freezed.dart';

class FolderFavoriteBloc
    extends Bloc<FolderFavoriteEvent, FolderFavoriteState> {
  FolderFavoriteBloc() : super(FolderFavoriteState.initial()) {
    _dispatch();
  }

  bool isReordering = false;

  void _dispatch() {
    on<FolderFavoriteEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            add(const FolderFavoriteEvent.fetchFavorites());
          },
          fetchFavorites: () async {
            // final result = await _service.readFavorites();
            // emit(
            //   result.fold(
            //     (favoriteViews) {
            //       final views = favoriteViews.items.toList();
            //       final pinnedViews =
            //           views.where((v) => v.item.isPinned).toList();
            //       final unpinnedViews =
            //           views.where((v) => !v.item.isPinned).toList();
            //       return state.copyWith(
            //         isLoading: false,
            //         views: views,
            //         pinnedViews: pinnedViews,
            //         unpinnedViews: unpinnedViews,
            //       );
            //     },
            //     (error) => state.copyWith(
            //       isLoading: false,
            //       views: [],
            //     ),
            //   ),
            // );
          },
          toggle: (view) async {
            // final isFavorited = state.views.any((v) => v.item.id == view.id);
            // if (isFavorited) {
            //   await _service.unpinFavorite(view);
            // } else if (state.pinnedViews.length < 3) {
            //   // pin the view if there are less than 3 pinned views
            //   await _service.pinFavorite(view);
            // }

            // await _service.toggleFavorite(view.id);
          },
          pin: (view) async {
            // await _service.pinFavorite(view);
            // add(const FolderFavoriteEvent.fetchFavorites());
          },
          unpin: (view) async {
            // await _service.unpinFavorite(view);
            // add(const FolderFavoriteEvent.fetchFavorites());
          },
          reorder: (oldIndex, newIndex) async {
            /// TODO: this is a workaround to reorder the favorite views
            // isReordering = true;
            // final pinnedViews = state.pinnedViews.toList();
            // if (oldIndex < newIndex) newIndex -= 1;
            // final target = pinnedViews.removeAt(oldIndex);
            // pinnedViews.insert(newIndex, target);
            // emit(state.copyWith(pinnedViews: pinnedViews));
            // for (final view in pinnedViews) {
            //   await _service.toggleFavorite(view.item.id);
            //   await _service.toggleFavorite(view.item.id);
            // }
            // if (!isClosed) {
            //   add(const FolderFavoriteEvent.fetchFavorites());
            // }
            // isReordering = false;
          },
        );
      },
    );
  }

  void _onFavoritesUpdated(
    FlowyResult<RepeatedViewPB, FlowyError> favoriteOrFailed,
    bool didFavorite,
  ) {
    if (!isReordering) {
      favoriteOrFailed.fold(
        (favorite) => add(const FolderFavoriteEvent.fetchFavorites()),
        (error) => Log.error(error),
      );
    }
  }
}

@freezed
class FolderFavoriteEvent with _$FolderFavoriteEvent {
  const factory FolderFavoriteEvent.initial() = Initial;

  // toggle the favorite status of the view
  const factory FolderFavoriteEvent.toggle(FolderViewPB view) = Toggle;

  // fetch the favorites
  const factory FolderFavoriteEvent.fetchFavorites() = Fetch;

  // pin the view
  const factory FolderFavoriteEvent.pin(FolderViewPB view) = Pin;

  // unpin the view
  const factory FolderFavoriteEvent.unpin(FolderViewPB view) = Unpin;

  // reorder the views
  const factory FolderFavoriteEvent.reorder(int oldIndex, int newIndex) =
      ReorderFavorite;
}

@freezed
class FolderFavoriteState with _$FolderFavoriteState {
  const factory FolderFavoriteState({
    @Default([]) List<FolderViewPB> views,
    @Default([]) List<FolderViewPB> pinnedViews,
    @Default([]) List<FolderViewPB> unpinnedViews,
    @Default(true) bool isLoading,
  }) = _FolderFavoriteState;

  factory FolderFavoriteState.initial() => const FolderFavoriteState();
}
