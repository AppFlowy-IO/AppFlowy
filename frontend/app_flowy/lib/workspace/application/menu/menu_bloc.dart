import 'dart:async';
import 'package:app_flowy/workspace/domain/i_workspace.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/stack_page/blank/blank_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-core-infra/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-core/errors.pb.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_bloc.freezed.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final IWorkspace workspaceManager;
  final IWorkspaceListener listener;
  MenuBloc({required this.workspaceManager, required this.listener}) : super(MenuState.initial());

  @override
  Stream<MenuState> mapEventToState(
    MenuEvent event,
  ) async* {
    yield* event.map(
      initial: (e) async* {
        listener.start(addAppCallback: _handleAppsOrFail);
        yield* _fetchApps();
      },
      collapse: (e) async* {
        final isCollapse = state.isCollapse;
        yield state.copyWith(isCollapse: !isCollapse);
      },
      openPage: (e) async* {
        yield* _performActionOnOpenPage(e);
      },
      createApp: (CreateApp event) async* {
        yield* _performActionOnCreateApp(event);
      },
      didReceiveApps: (e) async* {
        yield e.appsOrFail.fold(
          (apps) => state.copyWith(apps: some(apps), successOrFailure: left(unit)),
          (err) => state.copyWith(successOrFailure: right(err)),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }

  Stream<MenuState> _performActionOnOpenPage(OpenPage e) async* {
    yield state.copyWith(stackContext: e.context);
  }

  Stream<MenuState> _performActionOnCreateApp(CreateApp event) async* {
    final result = await workspaceManager.createApp(name: event.name, desc: event.desc);
    yield result.fold(
      (app) => state.copyWith(apps: some([app])),
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    );
  }

  // ignore: unused_element
  Stream<MenuState> _fetchApps() async* {
    final appsOrFail = await workspaceManager.getApps();
    yield appsOrFail.fold(
      (apps) => state.copyWith(apps: some(apps)),
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    );
  }

  void _handleAppsOrFail(Either<List<App>, WorkspaceError> appsOrFail) {
    appsOrFail.fold(
      (apps) => add(MenuEvent.didReceiveApps(left(apps))),
      (error) => add(MenuEvent.didReceiveApps(right(error))),
    );
  }
}

@freezed
class MenuEvent with _$MenuEvent {
  const factory MenuEvent.initial() = _Initial;
  const factory MenuEvent.collapse() = Collapse;
  const factory MenuEvent.openPage(HomeStackContext context) = OpenPage;
  const factory MenuEvent.createApp(String name, {String? desc}) = CreateApp;
  const factory MenuEvent.didReceiveApps(Either<List<App>, WorkspaceError> appsOrFail) = ReceiveApps;
}

@freezed
class MenuState with _$MenuState {
  const factory MenuState({
    required bool isCollapse,
    required Option<List<App>> apps,
    required Either<Unit, WorkspaceError> successOrFailure,
    required HomeStackContext stackContext,
  }) = _MenuState;

  factory MenuState.initial() => MenuState(
        isCollapse: false,
        apps: none(),
        successOrFailure: left(unit),
        stackContext: BlankStackContext(),
      );
}
