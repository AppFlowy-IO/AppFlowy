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
    required ViewPB view,
  }) : super(GridTabBarState.initial(view)) {
    on<GridTabBarEvent>(
      (event, emit) async {
        event.when(
          initial: () {
            _loadChildView();
          },
          didLoadChildViews: (List<DatabaseTarBar> childViews) {
            emit(
              state.copyWith(
                tabBars: [
                  state.selectedTabBar,
                  ...childViews,
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
            _createRefenceView(action.name, action.layoutType);
          },
          didReceiveRefView: (ViewPB refView) {
            final newView = DatabaseTarBar(view: refView);
            emit(
              state.copyWith(
                tabBars: [
                  ...state.tabBars,
                  newView,
                ],
                selectedTabBar: newView,
                selectedIndex: state.tabBars.length,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    for (final tabBar in state.tabBars) {
      await tabBar.controller.dispose();
    }
    return super.close();
  }

  Future<void> _createRefenceView(String name, ViewLayoutPB layoutType) async {
    final viewId = state.inlineView.id;
    final databaseIdOrError =
        await DatabaseViewBackendService(viewId: viewId).getDatabaseId();
    databaseIdOrError.fold(
      (databaseId) async {
        final refViewOrError =
            await ViewBackendService.createDatabaseReferenceView(
          parentViewId: viewId,
          databaseId: databaseId,
          layoutType: layoutType,
          name: name,
        );

        refViewOrError.fold(
          (refView) {
            if (!isClosed) {
              add(GridTabBarEvent.didReceiveRefView(refView));
            }
          },
          (err) => Log.error(err),
        );
      },
      (r) => Log.error(r),
    );
  }

  Future<void> _loadChildView() async {
    ViewBackendService.getChildViews(viewId: state.inlineView.id)
        .then((viewsOrFail) {
      if (isClosed) {
        return;
      }
      viewsOrFail.fold(
        (views) => add(
          GridTabBarEvent.didLoadChildViews(
            views.map((view) => DatabaseTarBar(view: view)).toList(),
          ),
        ),
        (err) => Log.error(err),
      );
    });
  }
}

@freezed
class GridTabBarEvent with _$GridTabBarEvent {
  const factory GridTabBarEvent.initial() = _Initial;
  const factory GridTabBarEvent.didLoadChildViews(
    List<DatabaseTarBar> childViews,
  ) = _DidLoadChildViews;
  const factory GridTabBarEvent.selectView(String viewId) = _DidSelectView;
  const factory GridTabBarEvent.createView(AddButtonAction action) =
      _DidCreateView;
  const factory GridTabBarEvent.didReceiveRefView(ViewPB refView) =
      _DidReceiveRefView;
}

@freezed
class GridTabBarState with _$GridTabBarState {
  const factory GridTabBarState({
    required ViewPB inlineView,
    required int selectedIndex,
    required DatabaseTarBar selectedTabBar,
    required List<DatabaseTarBar> tabBars,
  }) = _GridTabBarState;

  factory GridTabBarState.initial(ViewPB view) {
    final currentView = DatabaseTarBar(view: view);
    return GridTabBarState(
      inlineView: view,
      selectedIndex: 0,
      selectedTabBar: currentView,
      tabBars: [currentView],
    );
  }
}

class DatabaseTarBar {
  ViewPB view;
  DatabaseController controller;

  DatabaseTarBar({
    required this.view,
  }) : controller = DatabaseController(view: view);
}
