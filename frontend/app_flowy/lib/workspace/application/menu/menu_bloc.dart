import 'dart:async';
import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/workspace/application/workspace/workspace_listener.dart';
import 'package:app_flowy/workspace/application/workspace/workspace_service.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_bloc.freezed.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final WorkspaceService _workspaceService;
  final WorkspaceListener listener;
  final String workspaceId;

  MenuBloc({required this.workspaceId, required this.listener})
      : _workspaceService = WorkspaceService(workspaceId: workspaceId),
        super(MenuState.initial()) {
    on<MenuEvent>((event, emit) async {
      await event.map(
        initial: (e) async {
          listener.start(addAppCallback: _handleAppsOrFail);
          await _fetchApps(emit);
        },
        collapse: (e) async {
          final isCollapse = state.isCollapse;
          emit(state.copyWith(isCollapse: !isCollapse));
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
            _workspaceService.moveApp(appId: app.id, fromIndex: value.fromIndex, toIndex: value.toIndex);
            final apps = List<App>.from(state.apps);
            apps.insert(value.toIndex, apps.removeAt(value.fromIndex));
            emit(state.copyWith(apps: apps));
          }
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }

  Future<void> _performActionOnCreateApp(_CreateApp event, Emitter<MenuState> emit) async {
    final result = await _workspaceService.createApp(name: event.name, desc: event.desc ?? "");
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

  void _handleAppsOrFail(Either<List<App>, FlowyError> appsOrFail) {
    appsOrFail.fold(
      (apps) => add(MenuEvent.didReceiveApps(left(apps))),
      (error) => add(MenuEvent.didReceiveApps(right(error))),
    );
  }
}

@freezed
class MenuEvent with _$MenuEvent {
  const factory MenuEvent.initial() = _Initial;
  const factory MenuEvent.collapse() = _Collapse;
  const factory MenuEvent.openPage(Plugin plugin) = _OpenPage;
  const factory MenuEvent.createApp(String name, {String? desc}) = _CreateApp;
  const factory MenuEvent.moveApp(int fromIndex, int toIndex) = _MoveApp;
  const factory MenuEvent.didReceiveApps(Either<List<App>, FlowyError> appsOrFail) = _ReceiveApps;
}

@freezed
class MenuState with _$MenuState {
  const factory MenuState({
    required bool isCollapse,
    required List<App> apps,
    required Either<Unit, FlowyError> successOrFailure,
    required Plugin plugin,
  }) = _MenuState;

  factory MenuState.initial() => MenuState(
        isCollapse: false,
        apps: [],
        successOrFailure: left(unit),
        plugin: makePlugin(pluginType: DefaultPlugin.blank.type()),
      );
}
