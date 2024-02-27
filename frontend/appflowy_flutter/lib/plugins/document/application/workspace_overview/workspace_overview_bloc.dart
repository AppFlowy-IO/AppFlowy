import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy/workspace/application/workspace/overview/overview_listener.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workspace_overview_bloc.freezed.dart';

class WorkspaceOverviewBloc
    extends Bloc<WorkspaceOverviewEvent, WorkspaceOverviewState> {
  WorkspaceOverviewBloc({
    required this.view,
  })  : _listener = WorkspaceOverviewListener(viewId: view.id),
        super(WorkspaceOverviewState.initial(view)) {
    on<WorkspaceOverviewEvent>((event, emit) async {
      await WorkspaceOverviewListener.addListenerId(view.id);
      await event.map(
        initial: (e) async {
          _listener.start(
            onParentViewUpdated: (updatedParentView) async {
              final updatedView = await _onViewUpdated(updatedParentView);
              if (!isClosed && updatedView != null) {
                add(WorkspaceOverviewEvent.viewDidUpdate(updatedView));
              }
            },
            onChildViewsUpdated: (updatedChildViews) async {
              final updatedView = await _onChildViewsUpdated(updatedChildViews);
              if (!isClosed && updatedView != null) {
                add(WorkspaceOverviewEvent.viewUpdateChildViews(updatedView));
              }
            },
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

  final ViewPB view;

  final WorkspaceOverviewListener _listener;

  Future<ViewPB?> _onViewUpdated(UpdateViewNotifiedValue update) async {
    if (state.view.name != update.name || state.view.icon != update.icon) {
      final updatedView =
          await ViewBackendService.getAllLevelOfViews(state.view.id);
      return updatedView.fold((l) => l, (r) => null);
    }
    return null;
  }

  Future<ViewPB?> _onChildViewsUpdated(
    ChildViewUpdatePB update,
  ) async {
    if (update.createChildViews.isNotEmpty) {
      final view = await ViewBackendService.getAllLevelOfViews(
        state.view.id,
      );
      return view.fold((l) => l, (r) => null);
    }

    if (update.deleteChildViews.isNotEmpty) {
      final res = update.parentViewId == state.view.id
          ? (state.view, 0)
          : _getView(update.parentViewId, state.view);

      if (res != null) {
        final ViewPB view = res.$1;
        final int idx = res.$2;

        ViewPB? parentView;
        if (view.id != state.view.id && view.hasParentViewId()) {
          parentView = view.parentViewId == state.view.id
              ? state.view
              : _getView(view.parentViewId, state.view)?.$1;
        }

        final childViews = [...view.childViews];
        childViews.removeWhere(
          (v) => update.deleteChildViews.contains(v.id),
        );
        view.childViews.clear();
        view.childViews.addAll(childViews);

        if (parentView != null) {
          parentView.childViews.insert(idx, view);
          return state.view;
        }

        return view;
      }
    }

    // The update view payload mirrors `FolderNotification.DidUpdateChildViews`.
    // Retrieve the view specified in `update.parentViewId` from the cached views
    // stored in this state to determine if a rebuild is necessary.
    if (update.updateChildViews.isNotEmpty) {
      final view = _getView(update.parentViewId, state.view)?.$1;
      final childViews = view != null ? view.childViews : <ViewPB>[];

      if (_isRebuildRequired(childViews, update.updateChildViews)) {
        final updatedView = await ViewBackendService.getAllLevelOfViews(
          state.view.id,
        );
        return updatedView.fold(
          (l) => l,
          (r) {
            Log.error("Record not found for the viewId: ${state.view.id}");
            return null;
          },
        );
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
    }

    return false;
  }

  (ViewPB, int)? _getView(String viewId, ViewPB view) {
    for (int i = 0; i < view.childViews.length; i++) {
      final child = view.childViews[i];
      if (child.id == viewId) {
        return (child, i);
      }

      final result = _getView(viewId, child);
      if (result != null) {
        return result;
      }
    }

    return null;
  }

  @override
  Future<void> close() async {
    await WorkspaceOverviewListener.removeListener(view.id);
    await _listener.stop();
    return super.close();
  }
}

@freezed
class WorkspaceOverviewEvent with _$WorkspaceOverviewEvent {
  const factory WorkspaceOverviewEvent.initial() = Initial;
  const factory WorkspaceOverviewEvent.viewDidUpdate(
    ViewPB view,
  ) = ViewDidUpdate;
  const factory WorkspaceOverviewEvent.viewUpdateChildViews(
    ViewPB view,
  ) = ViewUpdateChildViews;
}

@freezed
class WorkspaceOverviewState with _$WorkspaceOverviewState {
  const factory WorkspaceOverviewState({
    required ViewPB view,
  }) = _WorkspaceOverviewState;

  factory WorkspaceOverviewState.initial(ViewPB view) => WorkspaceOverviewState(
        view: view,
      );
}
