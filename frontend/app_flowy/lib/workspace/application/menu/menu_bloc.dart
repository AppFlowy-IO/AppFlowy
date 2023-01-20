import 'dart:async';
import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/workspace/application/workspace/workspace_listener.dart';
import 'package:app_flowy/workspace/application/workspace/workspace_service.dart';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/app.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart';
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
          await _performActionOnCreateApp(event, emit);
        },
        didReceiveApps: (e) async {
          emit(e.appsOrFail.fold(
            (apps) => state.copyWith(apps: apps, successOrFailure: left(unit)),
            (err) => state.copyWith(successOrFailure: right(err)),
          ));
        },
        moveApp: (_MoveApp value) {
          if (state.apps.length > value.fromIndex) {
            final app = state.apps[value.fromIndex];
            _workspaceService.moveApp(
                appId: app.id,
                fromIndex: value.fromIndex,
                toIndex: value.toIndex);
            final apps = List<AppPB>.from(state.apps);
            apps.insert(value.toIndex, apps.removeAt(value.fromIndex));
            emit(state.copyWith(apps: apps));
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

  Future<void> _performActionOnCreateApp(
      _CreateApp event, Emitter<MenuState> emit) async {
    final result = await _workspaceService.createApp(
        name: event.name, desc: event.desc ?? "");
    result.fold(
      (app) => {},
      (error) {
        Log.error(error);
        emit(state.copyWith(successOrFailure: right(error)));
      },
    );
  }

  // ignore: unused_element
  Future<void> _fetchApps(Emitter<MenuState> emit) async {
    final appsOrFail = await _workspaceService.getApps();
    emit(appsOrFail.fold(
      (apps) => state.copyWith(apps: apps),
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    ));
  }

  void _handleAppsOrFail(Either<List<AppPB>, FlowyError> appsOrFail) {
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
      Either<List<AppPB>, FlowyError> appsOrFail) = _ReceiveApps;
}

@freezed
class MenuState with _$MenuState {
  const factory MenuState({
    required List<AppPB> apps,
    required Either<Unit, FlowyError> successOrFailure,
    required Plugin plugin,
  }) = _MenuState;

  factory MenuState.initial(WorkspacePB workspace) => MenuState(
        apps: workspace.apps.items,
        successOrFailure: left(unit),
        plugin: makePlugin(pluginType: PluginType.blank),
      );
}
