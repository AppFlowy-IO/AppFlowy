import 'package:app_flowy/workspace/domain/i_workspace.dart';
import 'package:flowy_log/flowy_log.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/app_create.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-workspace/errors.pb.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

part 'menu_listen.freezed.dart';

class MenuListenBloc extends Bloc<MenuListenEvent, MenuListenState> {
  final IWorkspaceWatch watch;
  MenuListenBloc(this.watch) : super(const MenuListenState.initial());

  @override
  Stream<MenuListenState> mapEventToState(MenuListenEvent event) async* {
    yield* event.map(
      started: (_) async* {
        watch.startWatching(
          addAppCallback: (appsOrFail) => _handleAppsOrFail(appsOrFail),
        );
      },
      appsReceived: (e) async* {
        yield e.appsOrFail.fold(
          (apps) => MenuListenState.loadApps(apps),
          (error) => MenuListenState.loadFail(error),
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await watch.stopWatching();
    return super.close();
  }

  void _handleAppsOrFail(Either<List<App>, WorkspaceError> appsOrFail) {
    appsOrFail.fold(
      (apps) => add(MenuListenEvent.appsReceived(left(apps))),
      (error) {
        Log.error(error);
        add(MenuListenEvent.appsReceived(right(error)));
      },
    );
  }
}

@freezed
class MenuListenEvent with _$MenuListenEvent {
  const factory MenuListenEvent.started() = _Started;
  const factory MenuListenEvent.appsReceived(Either<List<App>, WorkspaceError> appsOrFail) = AppsReceived;
}

@freezed
class MenuListenState with _$MenuListenState {
  const factory MenuListenState.initial() = _Initial;

  const factory MenuListenState.loadApps(
    List<App> apps,
  ) = _LoadApps;

  const factory MenuListenState.loadFail(
    WorkspaceError error,
  ) = _LoadFail;
}
