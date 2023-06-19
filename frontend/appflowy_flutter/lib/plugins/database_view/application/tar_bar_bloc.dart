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
  final ViewListener _listener;

  GridTabBarBloc({
    bool isInlineView = false,
    required ViewPB view,
  })  : _listener = ViewListener(viewId: view.id),
        super(GridTabBarState.initial(view)) {
    on<GridTabBarEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _listenOnInlineViewChanged();
            _loadChildView();
          },
          didLoadChildViews: (List<ViewPB> childViews) {
            final childTabBars =
                childViews.map((view) => DatabaseTarBar(view: view)).toList();

            emit(
              state.copyWith(
                tabBars: [
                  state.parentTabBar,
                  ...childTabBars,
                ],
              ),
            );
          },
          selectView: (String viewId) {
            final index = state.tabBars
                .indexWhere((element) => element.view.id == viewId);
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
              final newTabBar = updatePB.createChildViews
                  .map((e) => DatabaseTarBar(view: e))
                  .toList();
              final allTabBars = [...state.tabBars, ...newTabBar];
              emit(
                state.copyWith(
                  tabBars: allTabBars,
                  selectedTabBar: allTabBars.last,
                  selectedIndex: allTabBars.length - 1,
                ),
              );
            }

            if (updatePB.deleteChildViews.isNotEmpty) {
              final allTabBars = [...state.tabBars];
              for (final viewId in updatePB.deleteChildViews) {
                final index = allTabBars.indexWhere(
                  (element) => element.view.id == viewId,
                );
                if (index != -1) {
                  final tarBar = allTabBars.removeAt(index);
                  tarBar.dispose();
                }
              }
              emit(
                state.copyWith(
                  tabBars: allTabBars,
                  selectedTabBar: allTabBars.last,
                  selectedIndex: allTabBars.length - 1,
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
    for (final tabBar in state.tabBars) {
      await tabBar.dispose();
    }
    return super.close();
  }

  Future<void> _listenOnInlineViewChanged() async {
    _listener.start(
      onViewDeleted: (view) {},
      onViewUpdated: (view) {},
      onViewChildViewsUpdated: (updatePB) {
        if (!isClosed) {
          add(GridTabBarEvent.didUpdateChildViews(updatePB));
        }
      },
    );
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
}

@freezed
class GridTabBarState with _$GridTabBarState {
  const factory GridTabBarState({
    required ViewPB parentView,
    required DatabaseTarBar parentTabBar,
    required int selectedIndex,
    required DatabaseTarBar selectedTabBar,
    required List<DatabaseTarBar> tabBars,
  }) = _GridTabBarState;

  factory GridTabBarState.initial(ViewPB view) {
    final tarBar = DatabaseTarBar(view: view);
    return GridTabBarState(
      parentView: view,
      selectedIndex: 0,
      parentTabBar: tarBar,
      selectedTabBar: tarBar,
      tabBars: [tarBar],
    );
  }
}

class DatabaseTarBar {
  ViewPB view;
  DatabaseController controller;

  DatabaseTarBar({
    required this.view,
  }) : controller = DatabaseController(view: view);

  Future<void> dispose() async {
    await controller.dispose();
  }
}
