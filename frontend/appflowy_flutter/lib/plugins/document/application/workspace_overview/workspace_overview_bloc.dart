import 'package:appflowy/plugins/document/application/workspace_overview/overview_adapter_service.dart';
import 'package:appflowy/workspace/application/view/view_listener.dart';
import 'package:appflowy/workspace/application/view/view_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:protobuf/protobuf.dart';

part 'workspace_overview_bloc.freezed.dart';

class WorkspaceOverviewBloc
    extends Bloc<WorkspaceOverviewEvent, WorkspaceOverviewState> {
  final ViewPB view;

  final ViewListener _listener;

  WorkspaceOverviewBloc({
    required this.view,
  })  : _listener = ViewListener(viewId: view.id),
        super(WorkspaceOverviewState.initial(view)) {
    on<WorkspaceOverviewEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          await OverviewAdapterBackendService.addListenerId(view.id);
          _listener.start(
            onViewUpdated: _onViewUpdated,
            onWorkspaceOverviewChildViewsUpdated: (updatedChildViews) async {
              final updatedView = await _onChildViewsUpdated(updatedChildViews);
              if (!isClosed && updatedView != null) {
                add(
                  WorkspaceOverviewEvent.viewUpdateChildViews(
                    updatedView,
                  ),
                );
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

  void _onViewUpdated(UpdateViewNotifiedValue update) {
    state.view.name = update.name;
    state.view.icon = update.icon;
    add(WorkspaceOverviewEvent.viewDidUpdate(view));
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
      final view = _getView(update.parentViewId, state.view);

      if (view != null) {
        ViewPB? parentView;
        if (view.hasParentViewId()) {
          parentView = _getView(view.parentViewId, state.view);
        }

        final childViews = [...view.childViews];
        childViews.removeWhere(
          (v) => update.deleteChildViews.contains(v.id),
        );

        final updatedView = view.rebuild((p0) {
          p0.childViews.clear();
          p0.childViews.addAll(childViews);
        });

        if (parentView != null) parentView.childViews.add(updatedView);

        return parentView ?? updatedView;
      }
    }

    if (update.updateChildViews.isNotEmpty) {
      final view = _getView(update.parentViewId, state.view);
      final childViews = view != null ? view.childViews : <ViewPB>[];

      if (_isRebuildRequired(childViews, update.updateChildViews)) {
        final updatedView = await ViewBackendService.getAllLevelOfViews(
          state.view.id,
        );
        return updatedView.fold((l) => l, (r) => null);
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

  ViewPB? _getView(String viewId, ViewPB view) {
    if (viewId == view.id) {
      return view;
    }

    for (final ViewPB child in view.childViews) {
      if (child.id == viewId) {
        return child;
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
