import 'dart:async';
import 'package:app_flowy/workspace/domain/i_workspace.dart';
import 'package:app_flowy/workspace/domain/page_stack/page_stack.dart';
import 'package:app_flowy/workspace/presentation/stack_page/blank/blank_page.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/app.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_bloc.freezed.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final IWorkspace workspaceManager;
  final IWorkspaceListener listener;
  MenuBloc({required this.workspaceManager, required this.listener}) : super(MenuState.initial()) {
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
          emit(state.copyWith(stackContext: e.context));
        },
        createApp: (CreateApp event) async {
          await _performActionOnCreateApp(event, emit);
        },
        didReceiveApps: (e) async {
          emit(e.appsOrFail.fold(
            (apps) => state.copyWith(apps: some(apps), successOrFailure: left(unit)),
            (err) => state.copyWith(successOrFailure: right(err)),
          ));
        },
      );
    });
  }

  @override
  Future<void> close() async {
    await listener.stop();
    return super.close();
  }

  Future<void> _performActionOnCreateApp(CreateApp event, Emitter<MenuState> emit) async {
    final result = await workspaceManager.createApp(name: event.name, desc: event.desc);
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
    final appsOrFail = await workspaceManager.getApps();
    emit(appsOrFail.fold(
      (apps) => state.copyWith(apps: some(apps)),
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
  const factory MenuEvent.collapse() = Collapse;
  const factory MenuEvent.openPage(HomeStackContext context) = OpenPage;
  const factory MenuEvent.createApp(String name, {String? desc}) = CreateApp;
  const factory MenuEvent.didReceiveApps(Either<List<App>, FlowyError> appsOrFail) = ReceiveApps;
}

@freezed
class MenuState with _$MenuState {
  const factory MenuState({
    required bool isCollapse,
    required Option<List<App>> apps,
    required Either<Unit, FlowyError> successOrFailure,
    required HomeStackContext stackContext,
  }) = _MenuState;

  factory MenuState.initial() => MenuState(
        isCollapse: false,
        apps: none(),
        successOrFailure: left(unit),
        stackContext: BlankStackContext(),
      );
}
