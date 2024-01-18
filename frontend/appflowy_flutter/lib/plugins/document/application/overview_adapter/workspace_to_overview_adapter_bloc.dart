import 'package:appflowy/plugins/document/application/overview_adapter/overview_adapter_service.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'workspace_to_overview_adapter_bloc.freezed.dart';

class WorkspaceToOverviewAdapterBloc extends Bloc<
    WorkspaceToOverviewAdapterEvent, WorkspaceToOverviewAdapterState> {
  final ViewPB view;

  final ViewListener _listener;

  WorkspaceToOverviewAdapterBloc({
    required this.view,
  })  : _listener = ViewListener(viewId: view.id),
        super(WorkspaceToOverviewAdapterState.initial(view)) {
    on<WorkspaceToOverviewAdapterEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          await OverviewAdapterBackendService.addListenerId(view.id);
          _listener.start(
            onViewUpdated: _onViewUpdated,
            onViewChildViewsUpdated: (updatedChildViews) async {
              final updatedView = await _onChildViewsUpdated(updatedChildViews);
              if (!isClosed && updatedView != null) {
                add(
                  WorkspaceToOverviewAdapterEvent.viewUpdateChildViews(
                    updatedView,
                  ),
                );
              }
            },
            onViewMoveToTrash: _onDeleted,
            onViewRestored: _onViewRestored,
          );
        },
        viewDidUpdate: (e) async {
          emit(state.copyWith(view: e.view));
        },
        viewUpdateChildViews: (e) async {
          emit(state.copyWith(view: e.view));
        },
      );
    });
  }

  void _onViewUpdated(UpdateViewNotifiedValue updatedView) {
    view.name = updatedView.name;
    view.icon = updatedView.icon;
    add(WorkspaceToOverviewAdapterEvent.viewDidUpdate(view));
  }

  Future<ViewPB?> _onChildViewsUpdated(
    ChildViewUpdatePB updatedView,
  ) async {
    if (updatedView.createChildViews.isNotEmpty) {
      assert(updatedView.parentViewId == this.view.id);
      final view = await ViewBackendService.getAllLevelOfViews(
        this.view.id,
      );
      return view.fold((l) => l, (r) => null);
    }

    final childViews = [...view.childViews];
    if (updatedView.deleteChildViews.isNotEmpty) {
      childViews.removeWhere(
        (v) => updatedView.deleteChildViews.contains(v.id),
      );
      return view.rebuild((p0) {
        p0.childViews.clear();
        p0.childViews.addAll(childViews);
      });
    }

    if (updatedView.updateChildViews.isNotEmpty) {
      final view = await ViewBackendService.getAllLevelOfViews(
        this.view.id,
      );
      final childViews = view.fold((l) => l.childViews, (r) => <ViewPB>[]);
      if (_isRebuildRequired(childViews, updatedView.updateChildViews)) {
        return view.fold((l) => l, (r) => null);
      }
    }

    return null;
  }

  bool _isRebuildRequired(
    List<ViewPB> childViews,
    List<ViewPB> updatedChildViews,
  ) {
    if (childViews.length != updatedChildViews.length) {
      return true;
    }

    for (int i = 0; i < childViews.length; i++) {
      if (childViews[i].id != updatedChildViews[i].id ||
          childViews[i].name != updatedChildViews[i].name ||
          childViews[i].icon != updatedChildViews[i].icon) {
        return true;
      }

      if (_isRebuildRequired(
        childViews[i].childViews,
        updatedChildViews[i].childViews,
      )) {
        return true;
      }
    }

    return false;
  }

  void _onViewRestored(RestoreViewNotifiedValue restoredView) {}

  void _onDeleted(MoveToTrashNotifiedValue trashedView) {}

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }
}

@freezed
class WorkspaceToOverviewAdapterEvent with _$WorkspaceToOverviewAdapterEvent {
  const factory WorkspaceToOverviewAdapterEvent.initial() = Initial;
  const factory WorkspaceToOverviewAdapterEvent.viewDidUpdate(
    ViewPB view,
  ) = ViewDidUpdate;
  const factory WorkspaceToOverviewAdapterEvent.viewUpdateChildViews(
    ViewPB view,
  ) = ViewUpdateChildViews;
}

@freezed
class WorkspaceToOverviewAdapterState with _$WorkspaceToOverviewAdapterState {
  const factory WorkspaceToOverviewAdapterState({
    required ViewPB view,
  }) = _WorkspaceToOverviewAdapterState;

  factory WorkspaceToOverviewAdapterState.initial(ViewPB view) =>
      WorkspaceToOverviewAdapterState(
        view: view,
      );
}
