import 'package:appflowy_backend/log.dart';
import 'package:appflowy/workspace/application/favorite/favorite_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FavoriteCubit extends Cubit<bool> {
  final FavoriteService favoriteService;
  final String viewId;

  FavoriteCubit(this.favoriteService, this.viewId, bool isFavorite)
      : super(isFavorite);

  void toggleFavorite() async {
    final toggleFav = await favoriteService.toggleFavorite(viewId, state);
    toggleFav.fold(
      (_) {
        emit(!state);
      },
      (error) {
        Log.error(error);
      },
    );
  }
}
