import 'package:app_flowy/workspace/domain/i_app.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace-infra/view_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'app_bloc.freezed.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final IApp appManager;
  final IAppListenr listener;
  AppBloc({required App app, required this.appManager, required this.listener}) : super(AppState.initial(app));

  @override
  Stream<AppState> mapEventToState(
    AppEvent event,
  ) async* {
    yield* event.map(initial: (e) async* {
      listener.start(
        viewsChangeCallback: _handleViewsChanged,
        updatedCallback: (app) => add(AppEvent.appDidUpdate(app)),
      );
      yield* _fetchViews();
    }, createView: (CreateView value) async* {
      final viewOrFailed = await appManager.createView(name: value.name, desc: value.desc, viewType: value.viewType);
      yield viewOrFailed.fold(
        (view) => state.copyWith(
          latestCreatedView: view,
          successOrFailure: left(unit),
        ),
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      );
    }, didReceiveViews: (e) async* {
      yield* handleDidReceiveViews(e.views);
    }, delete: (e) async* {
      final result = await appManager.delete();
      yield result.fold(
        (unit) => state.copyWith(successOrFailure: left(unit)),
        (error) => state.copyWith(successOrFailure: right(error)),
      );
    }, rename: (e) async* {
      final result = await appManager.rename(e.newName);
      yield result.fold(
        (l) => state.copyWith(successOrFailure: left(unit)),
        (error) => state.copyWith(successOrFailure: right(error)),
      );
    }, appDidUpdate: (e) async* {
      yield state.copyWith(app: e.app);
    });
  }

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }

  void _handleViewsChanged(Either<List<View>, WorkspaceError> result) {
    result.fold(
      (views) => add(AppEvent.didReceiveViews(views)),
      (error) {
        Log.error(error);
      },
    );
  }

  Stream<AppState> handleDidReceiveViews(List<View> views) async* {
    final latestCreatedView = state.latestCreatedView;
    AppState newState = state.copyWith(views: views);
    if (latestCreatedView != null) {
      final index = views.indexWhere((element) => element.id == latestCreatedView.id);
      if (index == -1) {
        newState = newState.copyWith(latestCreatedView: null);
      }
    }

    yield newState;
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
  const factory AppEvent.delete() = Delete;
  const factory AppEvent.rename(String newName) = Rename;
  const factory AppEvent.didReceiveViews(List<View> views) = ReceiveViews;
  const factory AppEvent.appDidUpdate(App app) = AppDidUpdate;
}

@freezed
class AppState with _$AppState {
  const factory AppState({
    required App app,
    required bool isLoading,
    required List<View>? views,
    View? latestCreatedView,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _AppState;

  factory AppState.initial(App app) => AppState(
        app: app,
        isLoading: false,
        views: null,
        latestCreatedView: null,
        successOrFailure: left(unit),
      );
}
