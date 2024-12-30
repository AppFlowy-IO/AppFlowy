import 'package:appflowy/workspace/application/favorite/favorite_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_menu_bloc.freezed.dart';

class FavoriteMenuBloc extends Bloc<FavoriteMenuEvent, FavoriteMenuState> {
  FavoriteMenuBloc() : super(FavoriteMenuState.initial()) {
    on<FavoriteMenuEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final favoriteViews = await _service.readFavorites();
            List<ViewPB> views = [];
            List<ViewPB> todayViews = [];
            List<ViewPB> thisWeekViews = [];
            List<ViewPB> otherViews = [];

            favoriteViews.onSuccess((s) {
              _source = s;
              (views, todayViews, thisWeekViews, otherViews) = _getViews(s);
            });

            emit(
              state.copyWith(
                views: views,
                queriedViews: views,
                todayViews: todayViews,
                thisWeekViews: thisWeekViews,
                otherViews: otherViews,
              ),
            );
          },
          search: (query) async {
            if (_source == null) {
              return;
            }
            var (views, todayViews, thisWeekViews, otherViews) =
                _getViews(_source!);
            var queriedViews = views;

            if (query.isNotEmpty) {
              queriedViews = _filter(views, query);
              todayViews = _filter(todayViews, query);
              thisWeekViews = _filter(thisWeekViews, query);
              otherViews = _filter(otherViews, query);
            }

            emit(
              state.copyWith(
                views: views,
                queriedViews: queriedViews,
                todayViews: todayViews,
                thisWeekViews: thisWeekViews,
                otherViews: otherViews,
              ),
            );
          },
        );
      },
    );
  }

  final FavoriteService _service = FavoriteService();
  RepeatedFavoriteViewPB? _source;

  List<ViewPB> _filter(List<ViewPB> views, String query) => views
      .where((view) => view.name.toLowerCase().contains(query.toLowerCase()))
      .toList();

  // all, today, last week, other
  (List<ViewPB>, List<ViewPB>, List<ViewPB>, List<ViewPB>) _getViews(
    RepeatedFavoriteViewPB source,
  ) {
    final now = DateTime.now();

    final List<ViewPB> views = source.items.map((v) => v.item).toList();
    final List<ViewPB> todayViews = [];
    final List<ViewPB> thisWeekViews = [];
    final List<ViewPB> otherViews = [];

    for (final favoriteView in source.items) {
      final view = favoriteView.item;
      final date = DateTime.fromMillisecondsSinceEpoch(
        favoriteView.timestamp.toInt() * 1000,
      );
      final diff = now.difference(date).inDays;
      if (diff == 0) {
        todayViews.add(view);
      } else if (diff < 7) {
        thisWeekViews.add(view);
      } else {
        otherViews.add(view);
      }
    }

    return (views, todayViews, thisWeekViews, otherViews);
  }
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
    @Default([]) List<ViewPB> todayViews,
    @Default([]) List<ViewPB> thisWeekViews,
    @Default([]) List<ViewPB> otherViews,
  }) = _FavoriteMenuState;

  factory FavoriteMenuState.initial() => const FavoriteMenuState();
}
