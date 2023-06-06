import 'dart:collection';

import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/app/app_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:expandable/expandable.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'app_bloc.freezed.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final ViewBackendService appService;
  final AppListener appListener;

  AppBloc({required ViewPB view})
      : appService = ViewBackendService(),
        appListener = AppListener(viewId: view.id),
        super(AppState.initial(view)) {
    on<AppEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          _startListening();
          await _loadViews(emit);
        },
        createView: (CreateView value) async {
          await _createView(value, emit);
        },
        loadViews: (_) async {
          await _loadViews(emit);
        },
        delete: (e) async {
          await _deleteApp(emit);
        },
        deleteView: (deletedView) async {
          await _deleteView(emit, deletedView.viewId);
        },
        rename: (e) async {
          await _renameView(e, emit);
        },
        appDidUpdate: (e) async {
          final latestCreatedView = state.latestCreatedView;
          final views = e.app.childViews;
          AppState newState = state.copyWith(
            views: views,
            view: e.app,
          );
          if (latestCreatedView != null) {
            final index = views
                .indexWhere((element) => element.id == latestCreatedView.id);
            if (index == -1) {
              newState = newState.copyWith(latestCreatedView: null);
            }
            emit(newState);
          }
          emit(newState);
        },
      );
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
    final result = await ViewBackendService.updateView(
      viewId: state.view.id,
      name: e.newName,
    );
    result.fold(
      (l) => emit(state.copyWith(successOrFailure: left(unit))),
      (error) => emit(state.copyWith(successOrFailure: right(error))),
    );
  }

// Delete the current app
  Future<void> _deleteApp(Emitter<AppState> emit) async {
    final result = await ViewBackendService.delete(viewId: state.view.id);
    result.fold(
      (unit) => emit(state.copyWith(successOrFailure: left(unit))),
      (error) => emit(state.copyWith(successOrFailure: right(error))),
    );
  }

  Future<void> _deleteView(Emitter<AppState> emit, String viewId) async {
    final result = await ViewBackendService.deleteView(viewId: viewId);
    result.fold(
      (unit) => emit(state.copyWith(successOrFailure: left(unit))),
      (error) => emit(state.copyWith(successOrFailure: right(error))),
    );
  }

  Future<void> _createView(CreateView value, Emitter<AppState> emit) async {
    // create a child view for the current view
    final result = await ViewBackendService.createView(
      parentViewId: state.view.id,
      name: value.name,
      desc: value.desc ?? "",
      layoutType: value.pluginBuilder.layoutType!,
      initialDataBytes: value.initialDataBytes,
      ext: value.ext ?? {},
    );
    result.fold(
      (view) => emit(
        state.copyWith(
          latestCreatedView: value.openAfterCreated ? view : null,
          successOrFailure: left(unit),
        ),
      ),
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
    final viewsOrFailed =
        await ViewBackendService.getViews(viewId: state.view.id);
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

    /// ~~The initial data should be the JSON of the document~~
    /// ~~For example: {"document":{"type":"editor","children":[]}}~~
    ///
    /// - Document:
    ///   the initial data should be the string that can be converted into [DocumentDataPB]
    ///
    List<int>? initialDataBytes,
    Map<String, String>? ext,

    /// open the view after created
    @Default(true) bool openAfterCreated,
  }) = CreateView;
  const factory AppEvent.loadViews() = LoadApp;
  const factory AppEvent.delete() = DeleteApp;
  const factory AppEvent.deleteView(String viewId) = DeleteView;
  const factory AppEvent.rename(String newName) = Rename;
  const factory AppEvent.appDidUpdate(ViewPB app) = AppDidUpdate;
}

@freezed
class AppState with _$AppState {
  const factory AppState({
    required ViewPB view,
    required List<ViewPB> views,
    ViewPB? latestCreatedView,
    required Either<Unit, FlowyError> successOrFailure,
  }) = _AppState;

  factory AppState.initial(ViewPB view) => AppState(
        view: view,
        views: view.childViews,
        successOrFailure: left(unit),
      );
}

class AppViewDataContext extends ChangeNotifier {
  final String viewId;
  final ValueNotifier<List<ViewPB>> _viewsNotifier = ValueNotifier([]);
  final ValueNotifier<ViewPB?> _selectedViewNotifier = ValueNotifier(null);
  VoidCallback? _menuSharedStateListener;
  ExpandableController expandController =
      ExpandableController(initialExpanded: false);

  AppViewDataContext({required this.viewId}) {
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
    void Function(UnmodifiableListView<ViewPB>) callback,
  ) {
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
