import 'package:app_flowy/user/application/user_listener.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-error/code.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart'
    show WorkspaceSettingPB;
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final UserWorkspaceListener _listener;

  HomeBloc(
    UserProfilePB user,
    WorkspaceSettingPB workspaceSetting,
  )   : _listener = UserWorkspaceListener(userProfile: user),
        super(HomeState.initial(workspaceSetting)) {
    on<HomeEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!isClosed) {
                add(HomeEvent.didReceiveWorkspaceSetting(workspaceSetting));
              }
            });

            _listener.start(
              onAuthChanged: (result) => _authDidChanged(result),
              onSettingUpdated: (result) {
                result.fold(
                  (setting) =>
                      add(HomeEvent.didReceiveWorkspaceSetting(setting)),
                  (r) => Log.error(r),
                );
              },
            );
          },
          showLoading: (e) async {
            emit(state.copyWith(isLoading: e.isLoading));
          },
          didReceiveWorkspaceSetting: (_DidReceiveWorkspaceSetting value) {
            final latestView = workspaceSetting.hasLatestView()
                ? workspaceSetting.latestView
                : state.latestView;

            emit(state.copyWith(
              workspaceSetting: value.setting,
              latestView: latestView,
            ));
          },
          unauthorized: (_Unauthorized value) {
            emit(state.copyWith(unauthorized: true));
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _authDidChanged(Either<Unit, FlowyError> errorOrNothing) {
    errorOrNothing.fold((_) {}, (error) {
      if (error.code == ErrorCode.UserUnauthorized.value) {
        add(HomeEvent.unauthorized(error.msg));
      }
    });
  }
}

enum MenuResizeType {
  slide,
  drag,
}

extension MenuResizeTypeExtension on MenuResizeType {
  Duration duration() {
    switch (this) {
      case MenuResizeType.drag:
        return 30.milliseconds;
      case MenuResizeType.slide:
        return 350.milliseconds;
    }
  }
}

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.initial() = _Initial;
  const factory HomeEvent.showLoading(bool isLoading) = _ShowLoading;
  const factory HomeEvent.didReceiveWorkspaceSetting(
      WorkspaceSettingPB setting) = _DidReceiveWorkspaceSetting;
  const factory HomeEvent.unauthorized(String msg) = _Unauthorized;
}

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    required bool isLoading,
    required WorkspaceSettingPB workspaceSetting,
    ViewPB? latestView,
    required bool unauthorized,
  }) = _HomeState;

  factory HomeState.initial(WorkspaceSettingPB workspaceSetting) => HomeState(
        isLoading: false,
        workspaceSetting: workspaceSetting,
        latestView: null,
        unauthorized: false,
      );
}
