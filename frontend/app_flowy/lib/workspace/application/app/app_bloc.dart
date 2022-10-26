import 'dart:collection';

import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/app/app_listener.dart';
import 'package:app_flowy/workspace/application/app/app_service.dart';
import 'package:app_flowy/workspace/presentation/home/menu/menu.dart';
import 'package:expandable/expandable.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'app_bloc.freezed.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final AppService appService;
  final AppListener appListener;

  AppBloc({required AppPB app})
      : appService = AppService(),
        appListener = AppListener(appId: app.id),
        super(AppState.initial(app)) {
    on<AppEvent>((event, emit) async {
      await event.map(initial: (e) async {
        _startListening();
        await _loadViews(emit);
      }, createView: (CreateView value) async {
        await _createView(value, emit);
      }, loadViews: (_) async {
        await _loadViews(emit);
      }, delete: (e) async {
        await _deleteApp(emit);
      }, deleteView: (deletedView) async {
        await _deleteView(emit, deletedView.viewId);
      }, rename: (e) async {
        await _renameView(e, emit);
      }, appDidUpdate: (e) async {
        final latestCreatedView = state.latestCreatedView;
        final views = e.app.belongings.items;
        AppState newState = state.copyWith(
          views: views,
          app: e.app,
        );
        if (latestCreatedView != null) {
          final index =
              views.indexWhere((element) => element.id == latestCreatedView.id);
          if (index == -1) {
            newState = newState.copyWith(latestCreatedView: null);
          }
        }
        emit(newState);
      });
    });
  }

  void _startListening() {
    appListener.start(
      onAppUpdated: (app) {
        if (!isClosed) {
          add(AppEvent.appDidUpdate(app));
        }
      },
    );
  }

  Future<void> _renameView(Rename e, Emitter<AppState> emit) async {
    final result =
        await appService.updateApp(appId: state.app.id, name: e.newName);
    result.fold(
      (l) => emit(state.copyWith(successOrFailure: left(unit))),
      (error) => emit(state.copyWith(successOrFailure: right(error))),
    );
  }

// Delete the current app
  Future<void> _deleteApp(Emitter<AppState> emit) async {
    final result = await appService.delete(appId: state.app.id);
    result.fold(
      (unit) => emit(state.copyWith(successOrFailure: left(unit))),
      (error) => emit(state.copyWith(successOrFailure: right(error))),
    );
  }

  Future<void> _deleteView(Emitter<AppState> emit, String viewId) async {
    final result = await appService.deleteView(viewId: viewId);
    result.fold(
      (unit) => emit(state.copyWith(successOrFailure: left(unit))),
      (error) => emit(state.copyWith(successOrFailure: right(error))),
    );
  }

  Future<void> _createView(CreateView value, Emitter<AppState> emit) async {
    final result = await appService.createView(
      appId: state.app.id,
      name: value.name,
      desc: value.desc ?? "",
      dataFormatType: value.pluginBuilder.dataFormatType,
      pluginType: value.pluginBuilder.pluginType,
      layoutType: value.pluginBuilder.layoutType!,
    );
    result.fold(
      (view) => emit(state.copyWith(
        latestCreatedView: view,
        successOrFailure: left(unit),
      )),
      (error) {
        Log.error(error);
        emit(state.copyWith(successOrFailure: right(error)));
      },
    );
  }

  @override
  Future<void> close() async {
    await appListener.stop();
    return super.close();
  }

  Future<void> _loadViews(Emitter<AppState> emit) async {
    final viewsOrFailed = await appService.getViews(appId: state.app.id);
    viewsOrFailed.fold(
      (views) => emit(state.copyWith(views: views)),
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
    PluginBuilder pluginBuilder, {
    String? desc,
  }) = CreateView;
  const factory AppEvent.loadViews() = LoadApp;
  const factory AppEvent.delete() = DeleteApp;
  const factory AppEvent.deleteView(String viewId) = DeleteView;
  const factory AppEvent.rename(String newName) = Rename;
  const factory AppEvent.appDidUpdate(AppPB app) = AppDidUpdate;
}

@freezed
class AppState with _$AppState {
  const factory AppState({
    required AppPB app,
    required List<ViewPB> views,
    ViewPB? latestCreatedView,
    required Either<Unit, FlowyError> successOrFailure,
  }) = _AppState;

  factory AppState.initial(AppPB app) => AppState(
        app: app,
        views: app.belongings.items,
        successOrFailure: left(unit),
      );
}

class AppViewDataContext extends ChangeNotifier {
  final String appId;
  final ValueNotifier<List<ViewPB>> _viewsNotifier = ValueNotifier([]);
  final ValueNotifier<ViewPB?> _selectedViewNotifier = ValueNotifier(null);
  VoidCallback? _menuSharedStateListener;
  ExpandableController expandController =
      ExpandableController(initialExpanded: false);

  AppViewDataContext({required this.appId}) {
    _setLatestView(getIt<MenuSharedState>().latestOpenView);
    _menuSharedStateListener =
        getIt<MenuSharedState>().addLatestViewListener((view) {
      _setLatestView(view);
    });
  }

  VoidCallback addSelectedViewChangeListener(void Function(ViewPB?) callback) {
    listener() {
      callback(_selectedViewNotifier.value);
    }

    _selectedViewNotifier.addListener(listener);
    return listener;
  }

  void removeSelectedViewListener(VoidCallback listener) {
    _selectedViewNotifier.removeListener(listener);
  }

  void _setLatestView(ViewPB? view) {
    view?.freeze();

    if (_selectedViewNotifier.value != view) {
      _selectedViewNotifier.value = view;
      _expandIfNeed();
      notifyListeners();
    }
  }

  ViewPB? get selectedView => _selectedViewNotifier.value;

  set views(List<ViewPB> views) {
    if (_viewsNotifier.value != views) {
      _viewsNotifier.value = views;
      _expandIfNeed();
      notifyListeners();
    }
  }

  UnmodifiableListView<ViewPB> get views =>
      UnmodifiableListView(_viewsNotifier.value);

  VoidCallback addViewsChangeListener(
      void Function(UnmodifiableListView<ViewPB>) callback) {
    listener() {
      callback(views);
    }

    _viewsNotifier.addListener(listener);
    return listener;
  }

  void removeViewsListener(VoidCallback listener) {
    _viewsNotifier.removeListener(listener);
  }

  void _expandIfNeed() {
    if (_selectedViewNotifier.value == null) {
      return;
    }

    if (!_viewsNotifier.value.contains(_selectedViewNotifier.value)) {
      return;
    }

    if (expandController.expanded == false) {
      // Workaround: Delay 150 milliseconds to make the smooth animation while expanding
      Future.delayed(const Duration(milliseconds: 150), () {
        expandController.expanded = true;
      });
    }
  }

  @override
  void dispose() {
    if (_menuSharedStateListener != null) {
      getIt<MenuSharedState>()
          .removeLatestViewListener(_menuSharedStateListener!);
    }
    super.dispose();
  }
}
