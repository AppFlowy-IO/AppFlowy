import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/workspace/infrastructure/repos/app_repo.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'app_bloc.freezed.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final AppRepository repo;
  final AppListener listener;
  AppBloc({required App app, required this.repo, required this.listener}) : super(AppState.initial(app)) {
    on<AppEvent>((event, emit) async {
      await event.map(initial: (e) async {
        listener.startListening(
          viewsChanged: _handleViewsChanged,
          appUpdated: (app) => add(AppEvent.appDidUpdate(app)),
        );
        await _fetchViews(emit);
      }, createView: (CreateView value) async {
        final viewOrFailed = await repo.createView(
          name: value.name,
          desc: value.desc,
          dataType: value.dataType,
          pluginType: value.pluginType,
        );
        viewOrFailed.fold(
          (view) => emit(state.copyWith(
            latestCreatedView: view,
            successOrFailure: left(unit),
          )),
          (error) {
            Log.error(error);
            emit(state.copyWith(successOrFailure: right(error)));
          },
        );
      }, didReceiveViews: (e) async {
        await handleDidReceiveViews(e.views, emit);
      }, delete: (e) async {
        final result = await repo.delete();
        result.fold(
          (unit) => emit(state.copyWith(successOrFailure: left(unit))),
          (error) => emit(state.copyWith(successOrFailure: right(error))),
        );
      }, rename: (e) async {
        final result = await repo.updateApp(name: e.newName);
        result.fold(
          (l) => emit(state.copyWith(successOrFailure: left(unit))),
          (error) => emit(state.copyWith(successOrFailure: right(error))),
        );
      }, appDidUpdate: (e) async {
        emit(state.copyWith(app: e.app));
      });
    });
  }

  @override
  Future<void> close() async {
    await listener.close();
    return super.close();
  }

  void _handleViewsChanged(Either<List<View>, FlowyError> result) {
    result.fold(
      (views) => add(AppEvent.didReceiveViews(views)),
      (error) {
        Log.error(error);
      },
    );
  }

  Future<void> handleDidReceiveViews(List<View> views, Emitter<AppState> emit) async {
    final latestCreatedView = state.latestCreatedView;
    AppState newState = state.copyWith(views: views);
    if (latestCreatedView != null) {
      final index = views.indexWhere((element) => element.id == latestCreatedView.id);
      if (index == -1) {
        newState = newState.copyWith(latestCreatedView: null);
      }
    }

    emit(newState);
  }

  Future<void> _fetchViews(Emitter<AppState> emit) async {
    final viewsOrFailed = await repo.getViews();
    viewsOrFailed.fold(
      (apps) => emit(state.copyWith(views: apps)),
      (error) {
        Log.error(error);
        emit(state.copyWith(successOrFailure: right(error)));
      },
    );
  }
}

@freezed
class AppEvent with _$AppEvent {
  const factory AppEvent.initial() = Initial;
  const factory AppEvent.createView(
    String name,
    String desc,
    PluginDataType dataType,
    PluginType pluginType,
  ) = CreateView;
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
    required Either<Unit, FlowyError> successOrFailure,
  }) = _AppState;

  factory AppState.initial(App app) => AppState(
        app: app,
        isLoading: false,
        views: null,
        latestCreatedView: null,
        successOrFailure: left(unit),
      );
}
