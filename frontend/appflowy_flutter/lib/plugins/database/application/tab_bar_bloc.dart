import 'package:appflowy/plugins/database/domain/database_view_service.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/database/widgets/database_layout_ext.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:universal_platform/universal_platform.dart';

import 'database_controller.dart';

part 'tab_bar_bloc.freezed.dart';

class DatabaseTabBarBloc
    extends Bloc<DatabaseTabBarEvent, DatabaseTabBarState> {
  DatabaseTabBarBloc({required ViewPB view})
      : super(DatabaseTabBarState.initial(view)) {
    on<DatabaseTabBarEvent>(
      (event, emit) async {
        await event.when(
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
                    (newChildView) => DatabaseTabBar(view: newChildView),
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
          createView: (layout, name) {
            _createLinkedView(layout.layoutType, name ?? layout.layoutName);
          },
          deleteView: (String viewId) async {
            final result = await ViewBackendService.deleteView(viewId: viewId);
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
                    .map((e) => DatabaseTabBar(view: e)),
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
                ...state.tabBarControllerByViewId,
              };
              var newSelectedIndex = state.selectedIndex;
              for (final viewId in updatePB.deleteChildViews) {
                final index = allTabBars.indexWhere(
                  (element) => element.viewId == viewId,
                );
                if (index != -1) {
                  final tabBar = allTabBars.removeAt(index);
                  // Dispose the controller when the tab is removed.
                  final controller =
                      tabBarControllerByViewId.remove(tabBar.viewId);
                  await controller?.dispose();
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
              final updatedTabBar = DatabaseTabBar(view: updatedView);
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
      tabBar.dispose();
    }
    return super.close();
  }

  void _listenInlineViewChanged() {
    final controller = state.tabBarControllerByViewId[state.parentView.id];
    controller?.onViewUpdated = (newView) {
      add(DatabaseTabBarEvent.viewDidUpdate(newView));
    };

    // Only listen the child view changes when the parent view is inline.
    controller?.onViewChildViewChanged = (update) {
      add(DatabaseTabBarEvent.didUpdateChildViews(update));
    };
  }

  /// Create tab bar controllers for the new views and return the updated map.
  Map<String, DatabaseTabBarController> _extendsTabBarController(
    List<ViewPB> newViews,
  ) {
    final tabBarControllerByViewId = {...state.tabBarControllerByViewId};
    for (final view in newViews) {
      final controller = DatabaseTabBarController(view: view);
      controller.onViewUpdated = (newView) {
        add(DatabaseTabBarEvent.viewDidUpdate(newView));
      };

      tabBarControllerByViewId[view.id] = controller;
    }
    return tabBarControllerByViewId;
  }

  Future<void> _createLinkedView(ViewLayoutPB layoutType, String name) async {
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

  void _loadChildView() async {
    final viewsOrFail =
        await ViewBackendService.getChildViews(viewId: state.parentView.id);

    viewsOrFail.fold(
      (views) {
        if (!isClosed) {
          add(DatabaseTabBarEvent.didLoadChildViews(views));
        }
      },
      (err) => Log.error(err),
    );
  }
}

@freezed
class DatabaseTabBarEvent with _$DatabaseTabBarEvent {
  const factory DatabaseTabBarEvent.initial() = _Initial;
  const factory DatabaseTabBarEvent.didLoadChildViews(
    List<ViewPB> childViews,
  ) = _DidLoadChildViews;
  const factory DatabaseTabBarEvent.selectView(String viewId) = _DidSelectView;
  const factory DatabaseTabBarEvent.createView(
    DatabaseLayoutPB layout,
    String? name,
  ) = _CreateView;
  const factory DatabaseTabBarEvent.renameView(String viewId, String newName) =
      _RenameView;
  const factory DatabaseTabBarEvent.deleteView(String viewId) = _DeleteView;
  const factory DatabaseTabBarEvent.didUpdateChildViews(
    ChildViewUpdatePB updatePB,
  ) = _DidUpdateChildViews;
  const factory DatabaseTabBarEvent.viewDidUpdate(ViewPB view) = _ViewDidUpdate;
}

@freezed
class DatabaseTabBarState with _$DatabaseTabBarState {
  const factory DatabaseTabBarState({
    required ViewPB parentView,
    required int selectedIndex,
    required List<DatabaseTabBar> tabBars,
    required Map<String, DatabaseTabBarController> tabBarControllerByViewId,
  }) = _DatabaseTabBarState;

  factory DatabaseTabBarState.initial(ViewPB view) {
    final tabBar = DatabaseTabBar(view: view);
    return DatabaseTabBarState(
      parentView: view,
      selectedIndex: 0,
      tabBars: [tabBar],
      tabBarControllerByViewId: {
        view.id: DatabaseTabBarController(
          view: view,
        ),
      },
    );
  }
}

class DatabaseTabBar extends Equatable {
  DatabaseTabBar({
    required this.view,
  }) : _builder = UniversalPlatform.isMobile
            ? view.mobileTabBarItem()
            : view.tabBarItem();

  final ViewPB view;
  final DatabaseTabBarItemBuilder _builder;

  String get viewId => view.id;
  DatabaseTabBarItemBuilder get builder => _builder;
  ViewLayoutPB get layout => view.layout;

  @override
  List<Object?> get props => [view.hashCode];

  void dispose() {
    _builder.dispose();
  }
}

typedef OnViewUpdated = void Function(ViewPB newView);
typedef OnViewChildViewChanged = void Function(
  ChildViewUpdatePB childViewUpdate,
);

class DatabaseTabBarController {
  DatabaseTabBarController({required this.view})
      : controller = DatabaseController(view: view),
        viewListener = ViewListener(viewId: view.id) {
    viewListener.start(
      onViewChildViewsUpdated: (update) => onViewChildViewChanged?.call(update),
      onViewUpdated: (newView) {
        view = newView;
        onViewUpdated?.call(newView);
      },
    );
  }

  ViewPB view;
  final DatabaseController controller;
  final ViewListener viewListener;
  OnViewUpdated? onViewUpdated;
  OnViewChildViewChanged? onViewChildViewChanged;

  Future<void> dispose() async {
    await viewListener.stop();
    await controller.dispose();
  }
}
