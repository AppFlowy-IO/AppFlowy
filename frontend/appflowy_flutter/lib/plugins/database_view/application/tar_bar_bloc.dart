import 'package:appflowy/plugins/database_view/tar_bar/tar_bar_add_button.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
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
                  state.parentView,
                  ...childViews,
                ],
                tabBarControllerByViewId: _extendsTabBarController(childViews),
              ),
            );
          },
          selectView: (String viewId) {
            final index =
                state.tabBars.indexWhere((element) => element.id == viewId);
            if (index != -1) {
              emit(
                state.copyWith(
                  selectedTabBar: state.tabBars[index],
                  selectedIndex: index,
                ),
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
                ...updatePB.createChildViews
              ];
              emit(
                state.copyWith(
                  tabBars: allTabBars,
                  selectedTabBar: allTabBars.last,
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
              for (final viewId in updatePB.deleteChildViews) {
                final index = allTabBars.indexWhere(
                  (element) => element.id == viewId,
                );
                if (index != -1) {
                  final view = allTabBars.removeAt(index);
                  // Dispose the controller when the tab is removed.
                  final controller = tabBarControllerByViewId.remove(view.id);
                  controller?.dispose();
                }
              }
              emit(
                state.copyWith(
                  tabBars: allTabBars,
                  selectedTabBar: allTabBars.last,
                  selectedIndex: state.tabBars.length,
                  tabBarControllerByViewId: tabBarControllerByViewId,
                ),
              );
            }
          },
          viewDidUpdate: (ViewPB view) {
            final index = state.tabBars.indexWhere(
              (element) => element.id == view.id,
            );
            if (index != -1) {
              final tabBars = [...state.tabBars];
              tabBars[index] = view;
              emit(
                state.copyWith(
                  tabBars: tabBars,
                ),
              );
            }
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    for (final view in state.tabBars) {
      await state.tabBarControllerByViewId[view.id]?.dispose();
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
    required ViewPB selectedTabBar,
    required List<ViewPB> tabBars,
    required Map<String, DatabaseTarBarController> tabBarControllerByViewId,
  }) = _GridTabBarState;

  factory GridTabBarState.initial(ViewPB view) {
    return GridTabBarState(
      parentView: view,
      selectedIndex: 0,
      selectedTabBar: view,
      tabBars: [view],
      tabBarControllerByViewId: {
        view.id: DatabaseTarBarController(
          view: view,
        )
      },
    );
  }
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
