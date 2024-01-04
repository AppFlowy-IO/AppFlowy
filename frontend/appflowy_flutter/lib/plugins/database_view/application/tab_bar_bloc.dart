import 'package:appflowy/plugins/database_view/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/database_view/widgets/database_layout_ext.dart';
import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart' hide Log;
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'database_controller.dart';
import 'database_view_service.dart';

part 'tab_bar_bloc.freezed.dart';

class DatabaseTabBarBloc
    extends Bloc<DatabaseTabBarEvent, DatabaseTabBarState> {
  final String inlineViewId;

  DatabaseTabBarBloc({
    bool isInlineView = true,
    required this.inlineViewId,
  }) : super(DatabaseTabBarState.initial()) {
    on<DatabaseTabBarEvent>(
      (event, emit) async {
        event.when(
          initial: () async {
            _startListening();
            await _loadChildViews();
          },
          didLoadChildViews: (List<ViewPB> childViews) {
            emit(
              state.copyWith(
                isLoading: false,
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
            final result = await ViewBackendService.delete(viewId: viewId);
            result.fold((l) {}, (r) => Log.error(r));
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
    }
    return super.close();
  }

  void _startListening() {
    final controller = state.tabBarControllerByViewId[inlineViewId];
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
    final databaseIdOrError =
        await DatabaseViewBackendService(viewId: inlineViewId).getDatabaseId();
    databaseIdOrError.fold(
      (databaseId) async {
        final linkedViewOrError =
            await ViewBackendService.createDatabaseLinkedView(
          parentViewId: inlineViewId,
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

  Future<void> _loadChildViews() async {
    final viewsOrFail = await ViewBackendService.getChildViews(
      viewId: inlineViewId,
    );
    if (isClosed) {
      return;
    }
    viewsOrFail.fold(
      (views) => add(DatabaseTabBarEvent.didLoadChildViews(views)),
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
    required bool isLoading,
    required int selectedIndex,
    required List<DatabaseTabBar> tabBars,
    required Map<String, DatabaseTabBarController> tabBarControllerByViewId,
  }) = _DatabaseTabBarState;

  factory DatabaseTabBarState.initial() {
    return const DatabaseTabBarState(
      isLoading: true,
      selectedIndex: 0,
      tabBars: [],
      tabBarControllerByViewId: {},
    );
  }
}

class DatabaseTabBar extends Equatable {
  final ViewPB view;
  final DatabaseTabBarItemBuilder _builder;

  String get viewId => view.id;
  DatabaseTabBarItemBuilder get builder => _builder;
  ViewLayoutPB get layout => view.layout;

  DatabaseTabBar({
    required this.view,
  }) : _builder = PlatformExtension.isMobile
            ? view.mobileTabBarItem()
            : view.tabBarItem();

  @override
  List<Object?> get props => [view.hashCode];
}

typedef OnViewUpdated = void Function(ViewPB newView);
typedef OnViewChildViewChanged = void Function(
  ChildViewUpdatePB childViewUpdate,
);

class DatabaseTabBarController {
  ViewPB view;
  final DatabaseController controller;
  final ViewListener viewListener;
  OnViewUpdated? onViewUpdated;
  OnViewChildViewChanged? onViewChildViewChanged;

  DatabaseTabBarController({
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
