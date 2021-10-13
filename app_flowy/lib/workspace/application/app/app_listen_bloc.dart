import 'package:app_flowy/workspace/domain/i_app.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'app_listen_bloc.freezed.dart';

class AppListenBloc extends Bloc<AppListenEvent, AppListenState> {
  final IAppListenr listener;
  AppListenBloc(this.listener) : super(const AppListenState.initial());

  @override
  Stream<AppListenState> mapEventToState(
    AppListenEvent event,
  ) async* {
    yield* event.map(started: (_) async* {
      listener.start(
        viewsChangeCallback: (viewsOrFail) => _handleViewsOrFail(viewsOrFail),
      );
    }, didReceiveViews: (ViewsReceived value) async* {
      yield value.viewsOrFail.fold(
        (views) => AppListenState.didReceiveViews(views),
        (error) => AppListenState.loadFail(error),
      );
    });
  }

  void _handleViewsOrFail(Either<List<View>, WorkspaceError> viewsOrFail) {
    viewsOrFail.fold(
      (views) => add(AppListenEvent.didReceiveViews(left(views))),
      (error) => add(AppListenEvent.didReceiveViews(right(error))),
    );
  }
}

@freezed
class AppListenEvent with _$AppListenEvent {
  const factory AppListenEvent.started() = _Started;
  const factory AppListenEvent.didReceiveViews(Either<List<View>, WorkspaceError> viewsOrFail) = ViewsReceived;
}

@freezed
class AppListenState with _$AppListenState {
  const factory AppListenState.initial() = _Initial;

  const factory AppListenState.didReceiveViews(
    List<View> views,
  ) = _LoadViews;

  const factory AppListenState.loadFail(
    WorkspaceError error,
  ) = _LoadFail;
}
