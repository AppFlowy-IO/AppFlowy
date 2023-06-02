import 'dart:async';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/workspace/workspace_listener.dart';
import 'package:appflowy/workspace/application/workspace/workspace_service.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_bloc.freezed.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final WorkspaceService _workspaceService;
  final WorkspaceListener _listener;
  final UserProfilePB user;
  final WorkspacePB workspace;

  MenuBloc({
    required this.user,
    required this.workspace,
  })  : _workspaceService = WorkspaceService(workspaceId: workspace.id),
        _listener = WorkspaceListener(
          user: user,
          workspaceId: workspace.id,
        ),
        super(MenuState.initial(workspace)) {
    on<MenuEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          _listener.start(appsChanged: _handleAppsOrFail);
          await _fetchApps(emit);
        },
        openPage: (e) async {
          emit(state.copyWith(plugin: e.plugin));
        },
        createApp: (_CreateApp event) async {
          final result = await _workspaceService.createApp(
            name: event.name,
            desc: event.desc ?? "",
          );
          result.fold(
            (app) => {},
            (error) {
              Log.error(error);
              emit(state.copyWith(successOrFailure: right(error)));
            },
          );
        },
        didReceiveApps: (e) async {
          emit(
            e.appsOrFail.fold(
              (views) =>
                  state.copyWith(views: views, successOrFailure: left(unit)),
              (err) => state.copyWith(successOrFailure: right(err)),
            ),
          );
        },
        moveApp: (_MoveApp value) {
          if (state.views.length > value.fromIndex) {
            final view = state.views[value.fromIndex];
            _workspaceService.moveApp(
              appId: view.id,
              fromIndex: value.fromIndex,
              toIndex: value.toIndex,
            );
            final apps = List<ViewPB>.from(state.views);

            apps.insert(value.toIndex, apps.removeAt(value.fromIndex));
            emit(state.copyWith(views: apps));
          }
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  // ignore: unused_element
  Future<void> _fetchApps(Emitter<MenuState> emit) async {
    final appsOrFail = await _workspaceService.getViews();
    emit(
      appsOrFail.fold(
        (views) => state.copyWith(views: views),
        (error) {
          Log.error(error);
          return state.copyWith(successOrFailure: right(error));
        },
      ),
    );
  }

  void _handleAppsOrFail(Either<List<ViewPB>, FlowyError> appsOrFail) {
    appsOrFail.fold(
      (apps) => add(MenuEvent.didReceiveApps(left(apps))),
      (error) => add(MenuEvent.didReceiveApps(right(error))),
    );
  }
}

@freezed
class MenuEvent with _$MenuEvent {
  const factory MenuEvent.initial() = _Initial;
  const factory MenuEvent.openPage(Plugin plugin) = _OpenPage;
  const factory MenuEvent.createApp(String name, {String? desc}) = _CreateApp;
  const factory MenuEvent.moveApp(int fromIndex, int toIndex) = _MoveApp;
  const factory MenuEvent.didReceiveApps(
    Either<List<ViewPB>, FlowyError> appsOrFail,
  ) = _ReceiveApps;
}

@freezed
class MenuState with _$MenuState {
  const factory MenuState({
    required List<ViewPB> views,
    required Either<Unit, FlowyError> successOrFailure,
    required Plugin plugin,
  }) = _MenuState;

  factory MenuState.initial(WorkspacePB workspace) => MenuState(
        views: workspace.views,
        successOrFailure: left(unit),
        plugin: makePlugin(pluginType: PluginType.blank),
      );
}
