import 'dart:async';
import 'package:app_flowy/workspace/domain/i_workspace.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/flowy_logger.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_bloc.freezed.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final IWorkspace workspace;
  MenuBloc(this.workspace) : super(MenuState.initial());

  @override
  Stream<MenuState> mapEventToState(
    MenuEvent event,
  ) async* {
    yield* event.map(
      initial: (value) async* {
        yield* _fetchApps();
      },
      collapse: (e) async* {
        final isCollapse = state.isCollapse;
        yield state.copyWith(isCollapse: !isCollapse);
      },
      openPage: (OpenPage e) async* {
        yield* _performActionOnOpenPage(e);
      },
      createApp: (CreateApp event) async* {
        yield* _performActionOnCreateApp(event);
      },
    );
  }

  Stream<MenuState> _performActionOnOpenPage(OpenPage e) async* {
    yield state.copyWith(stackView: e.stackView);
  }

  Stream<MenuState> _performActionOnCreateApp(CreateApp event) async* {
    final result =
        await workspace.createApp(name: event.name, desc: event.desc);
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
    final appsOrFail = await workspace.getApps();
    yield appsOrFail.fold(
      (apps) => state.copyWith(apps: some(apps)),
      (error) {
        Log.error(error);
        return state.copyWith(successOrFailure: right(error));
      },
    );
  }
}

@freezed
abstract class MenuEvent with _$MenuEvent {
  const factory MenuEvent.initial() = _Initial;
  const factory MenuEvent.collapse() = Collapse;
  const factory MenuEvent.openPage(HomeStackView stackView) = OpenPage;
  const factory MenuEvent.createApp(String name, {String? desc}) = CreateApp;
}

@freezed
abstract class MenuState implements _$MenuState {
  const factory MenuState({
    required bool isCollapse,
    required Option<List<App>> apps,
    required Either<Unit, WorkspaceError> successOrFailure,
    HomeStackView? stackView,
  }) = _MenuState;

  factory MenuState.initial() => MenuState(
        isCollapse: false,
        apps: none(),
        successOrFailure: left(unit),
      );
}
