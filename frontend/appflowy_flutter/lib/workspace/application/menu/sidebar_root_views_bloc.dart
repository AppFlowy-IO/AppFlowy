import 'dart:async';

import 'package:appflowy/workspace/application/workspace/workspace_listener.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sidebar_root_views_bloc.freezed.dart';

class SidebarRootViewsBloc
    extends Bloc<SidebarRootViewsEvent, SidebarRootViewState> {
  SidebarRootViewsBloc() : super(SidebarRootViewState.initial()) {
    _dispatch();
  }

  late WorkspaceService _workspaceService;
  WorkspaceListener? _listener;

  @override
  Future<void> close() async {
    await _listener?.stop();
    return super.close();
  }

  void _dispatch() {
    on<SidebarRootViewsEvent>(
      (event, emit) async {
        await event.when(
          initial: (userProfile, workspaceId) async {
            _initial(userProfile, workspaceId);
            await _fetchApps(emit);
          },
          reset: (userProfile, workspaceId) async {
            await _listener?.stop();
            _initial(userProfile, workspaceId);
            await _fetchApps(emit);
          },
          createRootView: (name, desc, index) async {
            final result = await _workspaceService.createApp(
              name: name,
              desc: desc,
              index: index,
            );
            result.fold(
              (view) => emit(state.copyWith(lastCreatedRootView: view)),
              (error) {
                Log.error(error);
                emit(
                  state.copyWith(
                    successOrFailure: FlowyResult.failure(error),
                  ),
                );
              },
            );
          },
          didReceiveViews: (viewsOrFailure) async {
            emit(
              viewsOrFailure.fold(
                (views) => state.copyWith(
                  views: views,
                  successOrFailure: FlowyResult.success(null),
                ),
                (err) =>
                    state.copyWith(successOrFailure: FlowyResult.failure(err)),
              ),
            );
          },
          moveRootView: (int fromIndex, int toIndex) {
            if (state.views.length > fromIndex) {
              final view = state.views[fromIndex];

              _workspaceService.moveApp(
                appId: view.id,
                fromIndex: fromIndex,
                toIndex: toIndex,
              );

              final views = List<ViewPB>.from(state.views);
              views.insert(toIndex, views.removeAt(fromIndex));
              emit(state.copyWith(views: views));
            }
          },
        );
      },
    );
  }

  Future<void> _fetchApps(Emitter<SidebarRootViewState> emit) async {
    final viewsOrError = await _workspaceService.getViews();
    emit(
      viewsOrError.fold(
        (views) => state.copyWith(views: views),
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: FlowyResult.failure(error));
        },
      ),
    );
  }

  void _handleAppsOrFail(FlowyResult<List<ViewPB>, FlowyError> viewsOrFail) {
    viewsOrFail.fold(
      (views) => add(
        SidebarRootViewsEvent.didReceiveViews(FlowyResult.success(views)),
      ),
      (error) => add(
        SidebarRootViewsEvent.didReceiveViews(FlowyResult.failure(error)),
      ),
    );
  }

  void _initial(UserProfilePB userProfile, String workspaceId) {
    _workspaceService = WorkspaceService(workspaceId: workspaceId);
    _listener = WorkspaceListener(
      user: userProfile,
      workspaceId: workspaceId,
    )..start(appsChanged: _handleAppsOrFail);
  }
}

@freezed
class SidebarRootViewsEvent with _$SidebarRootViewsEvent {
  const factory SidebarRootViewsEvent.initial(
    UserProfilePB userProfile,
    String workspaceId,
  ) = _Initial;
  const factory SidebarRootViewsEvent.reset(
    UserProfilePB userProfile,
    String workspaceId,
  ) = _Reset;
  const factory SidebarRootViewsEvent.createRootView(
    String name, {
    String? desc,
    int? index,
  }) = _createRootView;
  const factory SidebarRootViewsEvent.moveRootView(int fromIndex, int toIndex) =
      _MoveRootView;
  const factory SidebarRootViewsEvent.didReceiveViews(
    FlowyResult<List<ViewPB>, FlowyError> appsOrFail,
  ) = _ReceiveApps;
}

@freezed
class SidebarRootViewState with _$SidebarRootViewState {
  const factory SidebarRootViewState({
    required List<ViewPB> views,
    required FlowyResult<void, FlowyError> successOrFailure,
    @Default(null) ViewPB? lastCreatedRootView,
  }) = _SidebarRootViewState;

  factory SidebarRootViewState.initial() => SidebarRootViewState(
        views: [],
        successOrFailure: FlowyResult.success(null),
      );
}
