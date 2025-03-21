import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/extensions/favorite_folder_view_pb_extensions.dart';
import 'package:appflowy/workspace/presentation/home/menu/sidebar/experimental/services/favorite_http_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_favorite_bloc.freezed.dart';

class FolderFavoriteBloc
    extends Bloc<FolderFavoriteEvent, FolderFavoriteState> {
  FolderFavoriteBloc({required this.workspaceId})
      : _service = FavoriteHttpService(workspaceId: workspaceId),
        super(FolderFavoriteState.initial()) {
    _dispatch();
  }

  final String workspaceId;
  final FavoriteHttpService _service;

  void _dispatch() {
    on<FolderFavoriteEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            add(const FolderFavoriteEvent.fetchFavorites());
          },
          fetchFavorites: () async {
            final response = await _service.getFavoritePages();
            response.fold(
              (favoriteViews) {
                final views = favoriteViews;
                // FIXME: backend doesn't return isPinned
                final pinnedViews = views;
                final unpinnedViews = <FavoriteFolderViewPB>[];
                emit(
                  state.copyWith(
                    views: views,
                    pinnedViews: pinnedViews,
                    unpinnedViews: unpinnedViews,
                  ),
                );
              },
              (error) => Log.error(error),
            );
          },
          toggleFavorite: (viewId) async {
            final isFavorited = state.views.any((v) => v.id == viewId);
            if (isFavorited) {
              await _service.removeFavoritePage(pageId: viewId);
            } else {
              await _service.addFavoritePage(pageId: viewId);
            }

            add(const FolderFavoriteEvent.fetchFavorites());
          },
          pin: (view) async {
            await _service.pinFavoritePage(pageId: view.id);

            add(const FolderFavoriteEvent.fetchFavorites());
          },
          unpin: (view) async {
            await _service.unpinFavoritePage(pageId: view.id);

            add(const FolderFavoriteEvent.fetchFavorites());
          },
          reorder: (oldIndex, newIndex) async {
            // FIXME: backend doesn't support reordering
          },
        );
      },
    );
  }
}

@freezed
class FolderFavoriteEvent with _$FolderFavoriteEvent {
  const factory FolderFavoriteEvent.initial() = Initial;

  // toggle the favorite status of the view
  const factory FolderFavoriteEvent.toggleFavorite(String viewId) =
      ToggleFavorite;

  // fetch the favorites
  const factory FolderFavoriteEvent.fetchFavorites() = Fetch;

  // pin the view
  const factory FolderFavoriteEvent.pin(FavoriteFolderViewPB view) = Pin;

  // unpin the view
  const factory FolderFavoriteEvent.unpin(FavoriteFolderViewPB view) = Unpin;

  // reorder the views
  const factory FolderFavoriteEvent.reorder(int oldIndex, int newIndex) =
      ReorderFavorite;
}

@freezed
class FolderFavoriteState with _$FolderFavoriteState {
  const factory FolderFavoriteState({
    @Default([]) List<FavoriteFolderViewPB> views,
    @Default([]) List<FavoriteFolderViewPB> pinnedViews,
    @Default([]) List<FavoriteFolderViewPB> unpinnedViews,
    @Default(true) bool isLoading,
  }) = _FolderFavoriteState;

  factory FolderFavoriteState.initial() => const FolderFavoriteState();
}
