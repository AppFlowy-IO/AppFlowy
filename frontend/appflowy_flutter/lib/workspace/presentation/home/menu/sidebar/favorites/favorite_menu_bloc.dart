import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'favorite_menu_bloc.freezed.dart';

class FavoriteMenuBloc extends Bloc<FavoriteMenuEvent, FavoriteMenuState> {
  FavoriteMenuBloc() : super(FavoriteMenuState.initial()) {
    _dispatch();
  }

  void _dispatch() {
    on<FavoriteMenuEvent>(
      (event, emit) async {
        await event.when(
          initial: () async {
            final List<ViewPB> views = await ViewBackendService.getAllViews()
                .fold((s) => s.items, (f) => []);
            emit(state.copyWith(views: views, queriedViews: views));
          },
          search: (query) async {
            if (query.isEmpty) {
              emit(state.copyWith(queriedViews: state.views));
              return;
            }
            final queriedViews = state.views.where((view) {
              return view.name.toLowerCase().contains(query.toLowerCase());
            }).toList();
            print(queriedViews.map((e) => e.name));
            emit(state.copyWith(queriedViews: queriedViews));
          },
        );
      },
    );
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
    @Default([]) List<List<ViewPB>> todayViews,
    @Default([]) List<List<ViewPB>> lastWeekViews,
    @Default([]) List<List<ViewPB>> otherViews,
  }) = _FavoriteMenuState;

  factory FavoriteMenuState.initial() => const FavoriteMenuState();
}
