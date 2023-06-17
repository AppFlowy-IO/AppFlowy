import 'package:appflowy/workspace/application/view/prelude.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'database_controller.dart';

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
          didLoadChildViews: (List<DatabaseTarBarView> childViews) {
            emit(
              state.copyWith(
                tabBarViews: [
                  state.selectedTabBarView,
                  ...childViews,
                ],
              ),
            );
          },
          selectView: (String viewId) {
            final index = state.tabBarViews
                .indexWhere((element) => element.view.id == viewId);
            if (index != -1) {
              emit(
                state.copyWith(
                  selectedTabBarView: state.tabBarViews[index],
                  selectedViewIndex: index,
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _loadChildView() async {
    ViewBackendService.getChildViews(viewId: state.selectedView.id)
        .then((viewsOrFail) {
      if (isClosed) {
        return;
      }
      viewsOrFail.fold(
        (views) => add(
          GridTabBarEvent.didLoadChildViews(
            views.map((view) => DatabaseTarBarView(view: view)).toList(),
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
    List<DatabaseTarBarView> childViews,
  ) = _DidLoadChildViews;
  const factory GridTabBarEvent.selectView(String viewId) = _DidSelectView;
}

@freezed
class GridTabBarState with _$GridTabBarState {
  const factory GridTabBarState({
    required ViewPB selectedView,
    required int selectedViewIndex,
    required DatabaseTarBarView selectedTabBarView,
    required List<DatabaseTarBarView> tabBarViews,
  }) = _GridTabBarState;

  factory GridTabBarState.initial(ViewPB view) {
    final currentView = DatabaseTarBarView(view: view);
    return GridTabBarState(
      selectedView: view,
      selectedViewIndex: 0,
      selectedTabBarView: currentView,
      tabBarViews: [currentView],
    );
  }
}

class DatabaseTarBarView {
  ViewPB view;
  DatabaseController controller;

  DatabaseTarBarView({
    required this.view,
  }) : controller = DatabaseController(view: view);
}
