import 'dart:collection';

import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/app/app_listener.dart';
import 'package:appflowy/workspace/application/app/app_service.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:expandable/expandable.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'app_bloc.freezed.dart';

class AppBloc extends Bloc<AppEvent, AppState> {
  final AppBackendService appService;
  final AppListener appListener;

  AppBloc({required final AppPB app})
      : appService = AppBackendService(),
        appListener = AppListener(appId: app.id),
        super(AppState.initial(app)) {
    on<AppEvent>((final event, final emit) async {
      await event.map(
        initial: (final e) async {
          _startListening();
          await _loadViews(emit);
        },
        createView: (final CreateView value) async {
          await _createView(value, emit);
        },
        loadViews: (final _) async {
          await _loadViews(emit);
        },
        delete: (final e) async {
          await _deleteApp(emit);
        },
        deleteView: (final deletedView) async {
          await _deleteView(emit, deletedView.viewId);
        },
        rename: (final e) async {
          await _renameView(e, emit);
        },
        appDidUpdate: (final e) async {
          final latestCreatedView = state.latestCreatedView;
          final views = e.app.belongings.items;
          AppState newState = state.copyWith(
            views: views,
            app: e.app,
          );
          if (latestCreatedView != null) {
            final index = views
                .indexWhere((final element) => element.id == latestCreatedView.id);
            if (index == -1) {
              newState = newState.copyWith(latestCreatedView: null);
            }
          }
          emit(newState);
        },
      );
    });
  }

  void _startListening() {
    appListener.start(
      onAppUpdated: (final app) {
        if (!isClosed) {
          add(AppEvent.appDidUpdate(app));
        }
      },
    );
  }

  Future<void> _renameView(final Rename e, final Emitter<AppState> emit) async {
    final result =
        await appService.updateApp(appId: state.app.id, name: e.newName);
    result.fold(
      (final l) => emit(state.copyWith(successOrFailure: left(unit))),
      (final error) => emit(state.copyWith(successOrFailure: right(error))),
    );
  }

// Delete the current app
  Future<void> _deleteApp(final Emitter<AppState> emit) async {
    final result = await appService.delete(appId: state.app.id);
    result.fold(
      (final unit) => emit(state.copyWith(successOrFailure: left(unit))),
      (final error) => emit(state.copyWith(successOrFailure: right(error))),
    );
  }

  Future<void> _deleteView(final Emitter<AppState> emit, final String viewId) async {
    final result = await appService.deleteView(viewId: viewId);
    result.fold(
      (final unit) => emit(state.copyWith(successOrFailure: left(unit))),
      (final error) => emit(state.copyWith(successOrFailure: right(error))),
    );
  }

  Future<void> _createView(final CreateView value, final Emitter<AppState> emit) async {
    final result = await appService.createView(
      appId: state.app.id,
      name: value.name,
      desc: value.desc ?? "",
      layoutType: value.pluginBuilder.layoutType!,
      initialData: value.initialData,
      ext: value.ext ?? {},
    );
    result.fold(
      (final view) => emit(
        state.copyWith(
          latestCreatedView: view,
          successOrFailure: left(unit),
        ),
      ),
      (final error) {
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

  Future<void> _loadViews(final Emitter<AppState> emit) async {
    final viewsOrFailed = await appService.getViews(appId: state.app.id);
    viewsOrFailed.fold(
      (final views) => emit(state.copyWith(views: views)),
      (final error) {
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
    final String name,
    final PluginBuilder pluginBuilder, {
    final String? desc,

    /// The initial data should be the JSON of the document
    /// For example: {"document":{"type":"editor","children":[]}}
    final String? initialData,
    final Map<String, String>? ext,
  }) = CreateView;
  const factory AppEvent.loadViews() = LoadApp;
  const factory AppEvent.delete() = DeleteApp;
  const factory AppEvent.deleteView(final String viewId) = DeleteView;
  const factory AppEvent.rename(final String newName) = Rename;
  const factory AppEvent.appDidUpdate(final AppPB app) = AppDidUpdate;
}

@freezed
class AppState with _$AppState {
  const factory AppState({
    required final AppPB app,
    required final List<ViewPB> views,
    final ViewPB? latestCreatedView,
    required final Either<Unit, FlowyError> successOrFailure,
  }) = _AppState;

  factory AppState.initial(final AppPB app) => AppState(
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
        getIt<MenuSharedState>().addLatestViewListener((final view) {
      _setLatestView(view);
    });
  }

  VoidCallback addSelectedViewChangeListener(final void Function(ViewPB?) callback) {
    listener() {
      callback(_selectedViewNotifier.value);
    }

    _selectedViewNotifier.addListener(listener);
    return listener;
  }

  void removeSelectedViewListener(final VoidCallback listener) {
    _selectedViewNotifier.removeListener(listener);
  }

  void _setLatestView(final ViewPB? view) {
    view?.freeze();

    if (_selectedViewNotifier.value != view) {
      _selectedViewNotifier.value = view;
      _expandIfNeed();
      notifyListeners();
    }
  }

  ViewPB? get selectedView => _selectedViewNotifier.value;

  set views(final List<ViewPB> views) {
    if (_viewsNotifier.value != views) {
      _viewsNotifier.value = views;
      _expandIfNeed();
      notifyListeners();
    }
  }

  UnmodifiableListView<ViewPB> get views =>
      UnmodifiableListView(_viewsNotifier.value);

  VoidCallback addViewsChangeListener(
    final void Function(UnmodifiableListView<ViewPB>) callback,
  ) {
    listener() {
      callback(views);
    }

    _viewsNotifier.addListener(listener);
    return listener;
  }

  void removeViewsListener(final VoidCallback listener) {
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
