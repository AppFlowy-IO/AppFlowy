import 'package:appflowy/workspace/application/favorite/favorite_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_menu_bloc.freezed.dart';

class FavoriteMenuBloc extends Bloc<FavoriteMenuEvent, FavoriteMenuState> {
  FavoriteMenuBloc() : super(FavoriteMenuState.initial()) {
    on<FavoriteMenuEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final List<ViewPB> views =
                await _service.readFavorites().fold((s) => s.items, (f) => []);
            emit(state.copyWith(views: views, queriedViews: views));
          },
          search: (query) async {
            if (query.isEmpty) {
              emit(state.copyWith(queriedViews: state.views));
              return;
            }

            final queriedViews = state.views
                .where(
                  (view) =>
                      view.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
            emit(state.copyWith(queriedViews: queriedViews));
          },
        );
      },
    );
  }

  final FavoriteService _service = FavoriteService();
}

@freezed
class FavoriteMenuEvent with _$FavoriteMenuEvent {
  const factory FavoriteMenuEvent.initial() = Initial;
  const factory FavoriteMenuEvent.search(String query) = Search;
}

@freezed
class FavoriteMenuState with _$FavoriteMenuState {
  const factory FavoriteMenuState({
    @Default([]) List<ViewPB> views,
    @Default([]) List<ViewPB> queriedViews,
    @Default([]) List<List<ViewPB>> todayViews,
    @Default([]) List<List<ViewPB>> lastWeekViews,
    @Default([]) List<List<ViewPB>> otherViews,
  }) = _FavoriteMenuState;

  factory FavoriteMenuState.initial() => const FavoriteMenuState();
}
