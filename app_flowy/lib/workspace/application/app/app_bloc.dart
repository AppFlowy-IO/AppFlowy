import 'package:app_flowy/workspace/domain/i_app.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/view_create.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'app_bloc.freezed.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final IApp appManager;
  final IAppListenr listener;
  AppBloc({required this.appManager, required this.listener}) : super(AppState.initial());

  @override
  Stream<AppState> mapEventToState(
    AppEvent event,
  ) async* {
    yield* event.map(
      initial: (e) async* {
        listener.start(viewsChangeCallback: _handleViewsOrFail);

        yield* _fetchViews();
      },
      createView: (CreateView value) async* {
        final viewOrFailed = await appManager.createView(name: value.name, desc: value.desc, viewType: value.viewType);
        yield viewOrFailed.fold((view) => state, (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        });
      },
      didReceiveViews: (e) async* {
        yield state.copyWith(views: e.views);
      },
    );
  }

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }

  void _handleViewsOrFail(Either<List<View>, WorkspaceError> viewsOrFail) {
    viewsOrFail.fold(
      (views) => add(AppEvent.didReceiveViews(views)),
      (error) {
        Log.error(error);
      },
    );
  }

  Stream<AppState> _fetchViews() async* {
    final viewsOrFailed = await appManager.getViews();
    yield viewsOrFailed.fold(
      (apps) => state.copyWith(views: apps),
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    );
  }
}

@freezed
class AppEvent with _$AppEvent {
  const factory AppEvent.initial() = Initial;
  const factory AppEvent.createView(String name, String desc, ViewType viewType) = CreateView;
  const factory AppEvent.didReceiveViews(List<View> views) = ReceiveViews;
}

@freezed
class AppState with _$AppState {
  const factory AppState({
    required bool isLoading,
    required List<View>? views,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _AppState;

  factory AppState.initial() => AppState(
        isLoading: false,
        views: null,
        successOrFailure: left(unit),
      );
}
