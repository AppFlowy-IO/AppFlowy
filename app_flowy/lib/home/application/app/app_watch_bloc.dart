import 'package:app_flowy/home/domain/i_app.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'app_watch_bloc.freezed.dart';

class AppWatchBloc extends Bloc<AppWatchEvent, AppWatchState> {
  final IAppWatch watcher;
  AppWatchBloc(this.watcher) : super(const AppWatchState.initial());

  @override
  Stream<AppWatchState> mapEventToState(
    AppWatchEvent event,
  ) async* {
    yield* event.map(started: (_) {
      watcher.startWatching(
        addViewCallback: (viewsOrFail) => _handleViewsOrFail(viewsOrFail),
      );
    }, viewsReceived: (ViewsReceived value) async* {
      yield value.viewsOrFail.fold(
        (views) => AppWatchState.loadViews(views),
        (error) => AppWatchState.loadFail(error),
      );
    });
  }

  void _handleViewsOrFail(Either<List<View>, WorkspaceError> viewsOrFail) {
    viewsOrFail.fold(
      (views) => add(AppWatchEvent.viewsReceived(left(views))),
      (error) => add(AppWatchEvent.viewsReceived(right(error))),
    );
  }
}

@freezed
abstract class AppWatchEvent with _$AppWatchEvent {
  const factory AppWatchEvent.started() = _Started;
  const factory AppWatchEvent.viewsReceived(
      Either<List<View>, WorkspaceError> viewsOrFail) = ViewsReceived;
}

@freezed
abstract class AppWatchState implements _$AppWatchState {
  const factory AppWatchState.initial() = _Initial;

  const factory AppWatchState.loadViews(
    List<View> views,
  ) = _LoadViews;

  const factory AppWatchState.loadFail(
    WorkspaceError error,
  ) = _LoadFail;
}
