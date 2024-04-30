import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/recent/cached_recent_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_views_bloc.freezed.dart';

class RecentViewsBloc extends Bloc<RecentViewsEvent, RecentViewsState> {
  RecentViewsBloc() : super(RecentViewsState.initial()) {
    _service = getIt<CachedRecentService>();
    _dispatch();
  }

  late final CachedRecentService _service;

  @override
  Future<void> close() async {
    _service.notifier.removeListener(_onRecentViewsUpdated);
    return super.close();
  }

  void _dispatch() {
    on<RecentViewsEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            _service.notifier.addListener(_onRecentViewsUpdated);
            add(const RecentViewsEvent.fetchRecentViews());
          },
          addRecentViews: (e) async {
            await _service.updateRecentViews(e.viewIds, true);
          },
          removeRecentViews: (e) async {
            await _service.updateRecentViews(e.viewIds, false);
          },
          fetchRecentViews: (e) async {
            emit(state.copyWith(views: await _service.recentViews()));
          },
          resetRecentViews: (e) async {
            await _service.reset();
            add(const RecentViewsEvent.fetchRecentViews());
          },
        );
      },
    );
  }

  void _onRecentViewsUpdated() =>
      add(const RecentViewsEvent.fetchRecentViews());
}

@freezed
class RecentViewsEvent with _$RecentViewsEvent {
  const factory RecentViewsEvent.initial() = Initial;
  const factory RecentViewsEvent.addRecentViews(List<String> viewIds) =
      AddRecentViews;
  const factory RecentViewsEvent.removeRecentViews(List<String> viewIds) =
      RemoveRecentViews;
  const factory RecentViewsEvent.fetchRecentViews() = FetchRecentViews;
  const factory RecentViewsEvent.resetRecentViews() = ResetRecentViews;
}

@freezed
class RecentViewsState with _$RecentViewsState {
  const factory RecentViewsState({
    required List<ViewPB> views,
  }) = _RecentViewsState;

  factory RecentViewsState.initial() => const RecentViewsState(views: []);
}
