import 'dart:async';
import 'package:app_flowy/home/domain/i_workspace.dart';
import 'package:app_flowy/home/domain/page_context.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'menu_event.dart';
part 'menu_state.dart';
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
        iWorkspaceImpl.startWatching(addAppCallback: (appsOrFail) {
          appsOrFail.fold(
            (apps) => add(MenuEvent.appsReceived(left(apps))),
            (error) => add(MenuEvent.appsReceived(right(error))),
          );
        });
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
      appsReceived: (AppsReceived value) async* {
        yield value.appsOrFail.fold(
          (apps) => state.copyWith(apps: some(apps)),
          (error) => state.copyWith(successOrFailure: right(error)),
        );
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

  @override
  Future<void> close() {
    return super.close();
  }
}
