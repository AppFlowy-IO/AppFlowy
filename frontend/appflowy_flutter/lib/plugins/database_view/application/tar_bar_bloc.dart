import 'package:appflowy/plugins/database_view/tar_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/database_view/tar_bar/tar_bar_add_button.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'database_controller.dart';
import 'database_view_service.dart';

part 'tar_bar_bloc.freezed.dart';

class GridTabBarBloc extends Bloc<GridTabBarEvent, GridTabBarState> {
  GridTabBarBloc({
    bool isInlineView = false,
    required ViewPB view,
  }) : super(GridTabBarState.initial(view)) {
    on<GridTabBarEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _listenInlineViewChanged();
            _loadChildView();
          },
          didLoadChildViews: (List<ViewPB> childViews) {
            emit(
              state.copyWith(
                tabBars: [
                  ...state.tabBars,
                  ...childViews.map(
                    (newChildView) => TarBar(view: newChildView),
                  ),
                ],
                tabBarControllerByViewId: _extendsTabBarController(childViews),
              ),
            );
          },
          selectView: (String viewId) {
            final index =
                state.tabBars.indexWhere((element) => element.viewId == viewId);
            if (index != -1) {
              emit(
                state.copyWith(selectedIndex: index),
              );
            }
          },
          createView: (action) {
            _createLinkedView(action.name, action.layoutType);
          },
          deleteView: (String viewId) async {
            final result = await ViewBackendService.delete(viewId: viewId);
            result.fold(
              (l) {},
              (r) => Log.error(r),
            );
          },
          renameView: (String viewId, String newName) {
            ViewBackendService.updateView(viewId: viewId, name: newName);
          },
          didUpdateChildViews: (updatePB) async {
            if (updatePB.createChildViews.isNotEmpty) {
              final allTabBars = [
                ...state.tabBars,
                ...updatePB.createChildViews.map((e) => TarBar(view: e))
              ];
              emit(
                state.copyWith(
                  tabBars: allTabBars,
                  selectedIndex: state.tabBars.length,
                  tabBarControllerByViewId:
                      _extendsTabBarController(updatePB.createChildViews),
                ),
              );
            }

            if (updatePB.deleteChildViews.isNotEmpty) {
              final allTabBars = [...state.tabBars];
              final tabBarControllerByViewId = {
                ...state.tabBarControllerByViewId
              };
              var newSelectedIndex = state.selectedIndex;
              for (final viewId in updatePB.deleteChildViews) {
                final index = allTabBars.indexWhere(
                  (element) => element.viewId == viewId,
                );
                if (index != -1) {
                  final tarBar = allTabBars.removeAt(index);
                  // Dispose the controller when the tab is removed.
                  final controller =
                      tabBarControllerByViewId.remove(tarBar.viewId);
                  controller?.dispose();
                }

                if (index == state.selectedIndex) {
                  if (index > 0 && allTabBars.isNotEmpty) {
                    newSelectedIndex = index - 1;
                  }
                }
              }
              emit(
                state.copyWith(
                  tabBars: allTabBars,
                  selectedIndex: newSelectedIndex,
                  tabBarControllerByViewId: tabBarControllerByViewId,
                ),
              );
            }
          },
          viewDidUpdate: (ViewPB updatedView) {
            final index = state.tabBars.indexWhere(
              (element) => element.viewId == updatedView.id,
            );
            if (index != -1) {
              final allTabBars = [...state.tabBars];
              final updatedTabBar = TarBar(view: updatedView);
              allTabBars[index] = updatedTabBar;
              emit(state.copyWith(tabBars: allTabBars));
            }
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    for (final tabBar in state.tabBars) {
      await state.tabBarControllerByViewId[tabBar.viewId]?.dispose();
    }
    return super.close();
  }

  void _listenInlineViewChanged() {
    final controller = state.tabBarControllerByViewId[state.parentView.id];
    controller?.onViewUpdated = (newView) {
      add(GridTabBarEvent.viewDidUpdate(newView));
    };

    // Only listen the child view changes when the parent view is inline.
    controller?.onViewChildViewChanged = (update) {
      add(GridTabBarEvent.didUpdateChildViews(update));
    };
  }

  /// Create tab bar controllers for the new views and return the updated map.
  Map<String, DatabaseTarBarController> _extendsTabBarController(
    List<ViewPB> newViews,
  ) {
    final tabBarControllerByViewId = {...state.tabBarControllerByViewId};
    for (final view in newViews) {
      final controller = DatabaseTarBarController(view: view);
      controller.onViewUpdated = (newView) {
        add(GridTabBarEvent.viewDidUpdate(newView));
      };

      tabBarControllerByViewId[view.id] = controller;
    }
    return tabBarControllerByViewId;
  }

  Future<void> _createLinkedView(String name, ViewLayoutPB layoutType) async {
    final viewId = state.parentView.id;
    final databaseIdOrError =
        await DatabaseViewBackendService(viewId: viewId).getDatabaseId();
    databaseIdOrError.fold(
      (databaseId) async {
        final linkedViewOrError =
            await ViewBackendService.createDatabaseLinkedView(
          parentViewId: viewId,
          databaseId: databaseId,
          layoutType: layoutType,
          name: name,
        );

        linkedViewOrError.fold(
          (linkedView) {},
          (err) => Log.error(err),
        );
      },
      (r) => Log.error(r),
    );
  }

  Future<void> _loadChildView() async {
    ViewBackendService.getChildViews(viewId: state.parentView.id)
        .then((viewsOrFail) {
      if (isClosed) {
        return;
      }
      viewsOrFail.fold(
        (views) => add(GridTabBarEvent.didLoadChildViews(views)),
        (err) => Log.error(err),
      );
    });
  }
}

@freezed
class GridTabBarEvent with _$GridTabBarEvent {
  const factory GridTabBarEvent.initial() = _Initial;
  const factory GridTabBarEvent.didLoadChildViews(
    List<ViewPB> childViews,
  ) = _DidLoadChildViews;
  const factory GridTabBarEvent.selectView(String viewId) = _DidSelectView;
  const factory GridTabBarEvent.createView(AddButtonAction action) =
      _CreateView;
  const factory GridTabBarEvent.renameView(String viewId, String newName) =
      _RenameView;
  const factory GridTabBarEvent.deleteView(String viewId) = _DeleteView;
  const factory GridTabBarEvent.didUpdateChildViews(
    ChildViewUpdatePB updatePB,
  ) = _DidUpdateChildViews;
  const factory GridTabBarEvent.viewDidUpdate(ViewPB view) = _ViewDidUpdate;
}

@freezed
class GridTabBarState with _$GridTabBarState {
  const factory GridTabBarState({
    required ViewPB parentView,
    required int selectedIndex,
    required List<TarBar> tabBars,
    required Map<String, DatabaseTarBarController> tabBarControllerByViewId,
  }) = _GridTabBarState;

  factory GridTabBarState.initial(ViewPB view) {
    final tabBar = TarBar(view: view);
    return GridTabBarState(
      parentView: view,
      selectedIndex: 0,
      tabBars: [tabBar],
      tabBarControllerByViewId: {
        view.id: DatabaseTarBarController(
          view: view,
        )
      },
    );
  }
}

class TarBar extends Equatable {
  final ViewPB view;
  final DatabaseTabBarItemBuilder _builder;

  String get viewId => view.id;
  DatabaseTabBarItemBuilder get builder => _builder;
  ViewLayoutPB get layout => view.layout;

  TarBar({
    required this.view,
  }) : _builder = view.tarBarItem();

  @override
  List<Object?> get props => [view.hashCode];
}

typedef OnViewUpdated = void Function(ViewPB newView);
typedef OnViewChildViewChanged = void Function(
  ChildViewUpdatePB childViewUpdate,
);

class DatabaseTarBarController {
  ViewPB view;
  final DatabaseController controller;
  final ViewListener viewListener;
  OnViewUpdated? onViewUpdated;
  OnViewChildViewChanged? onViewChildViewChanged;

  DatabaseTarBarController({
    required this.view,
  })  : controller = DatabaseController(view: view),
        viewListener = ViewListener(viewId: view.id) {
    viewListener.start(
      onViewChildViewsUpdated: (update) {
        onViewChildViewChanged?.call(update);
      },
      onViewUpdated: (newView) {
        view = newView;
        onViewUpdated?.call(newView);
      },
    );
  }

  Future<void> dispose() async {
    await viewListener.stop();
    await controller.dispose();
  }
}
