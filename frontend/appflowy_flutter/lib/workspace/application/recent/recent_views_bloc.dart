import 'package:appflowy/workspace/application/recent/recent_listener.dart';
import 'package:appflowy/workspace/application/recent/recent_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'recent_views_bloc.freezed.dart';

class RecentViewsBloc extends Bloc<RecentViewsEvent, RecentViewsState> {
  RecentViewsBloc() : super(RecentViewsState.initial()) {
    _dispatch();
  }

  final _service = RecentService();
  final _listener = RecentViewsListener();

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _dispatch() {
    on<RecentViewsEvent>(
      (event, emit) async {
        await event.map(
          initial: (e) async {
            _listener.start(
              recentViewsUpdated: (result) => _onRecentViewsUpdated(result),
            );
            add(const RecentViewsEvent.fetchRecentViews());
          },
          addRecentViews: (e) async {
            await _service.updateRecentViews(e.viewIds, true);
          },
          removeRecentViews: (e) async {
            await _service.updateRecentViews(e.viewIds, false);
          },
          fetchRecentViews: (e) async {
            final result = await _service.readRecentViews();
            result.fold(
              (views) => emit(state.copyWith(views: views.items)),
              (error) => Log.error(error),
            );
          },
        );
      },
    );
  }

  void _onRecentViewsUpdated(
    FlowyResult<RepeatedViewIdPB, FlowyError> result,
  ) {
    add(const RecentViewsEvent.fetchRecentViews());
  }
}

@freezed
class RecentViewsEvent with _$RecentViewsEvent {
  const factory RecentViewsEvent.initial() = Initial;
  const factory RecentViewsEvent.addRecentViews(List<String> viewIds) =
      AddRecentViews;
  const factory RecentViewsEvent.removeRecentViews(List<String> viewIds) =
      RemoveRecentViews;
  const factory RecentViewsEvent.fetchRecentViews() = FetchRecentViews;
}

@freezed
class RecentViewsState with _$RecentViewsState {
  const factory RecentViewsState({
    required List<ViewPB> views,
  }) = _RecentViewsState;

  factory RecentViewsState.initial() => const RecentViewsState(
        views: [],
      );
}
