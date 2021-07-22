import 'dart:async';
import 'package:app_flowy/home/domain/i_workspace.dart';
import 'package:app_flowy/home/domain/page_context.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_bloc.freezed.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final IWorkspace iWorkspaceImpl;
  MenuBloc(this.iWorkspaceImpl) : super(MenuState.initial());

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
    yield state.copyWith(pageContext: some(e.context));
  }

  Stream<MenuState> _performActionOnCreateApp(CreateApp event) async* {
    await iWorkspaceImpl
        .createApp(name: event.name, desc: event.desc)
        .then((result) async* {
      result.fold(
        (app) => {},
        (error) async* {
          yield state.copyWith(successOrFailure: right(error));
        },
      );
    });
  }

  Stream<MenuState> _fetchApps() async* {
    final appsOrFail = await iWorkspaceImpl.getApps();
    yield appsOrFail.fold(
      (apps) => state.copyWith(apps: some(apps)),
      (error) => state.copyWith(successOrFailure: right(error)),
    );
  }
}

@freezed
abstract class MenuEvent with _$MenuEvent {
  const factory MenuEvent.initial() = _Initial;
  const factory MenuEvent.collapse() = Collapse;
  const factory MenuEvent.openPage(PageContext context) = OpenPage;
  const factory MenuEvent.createApp(String name, {String? desc}) = CreateApp;
}

@freezed
abstract class MenuState implements _$MenuState {
  const factory MenuState({
    required bool isCollapse,
    required Option<PageContext> pageContext,
    required Option<List<App>> apps,
    required Either<Unit, WorkspaceError> successOrFailure,
  }) = _MenuState;

  factory MenuState.initial() => MenuState(
        isCollapse: false,
        pageContext: none(),
        apps: none(),
        successOrFailure: left(unit),
      );
}
