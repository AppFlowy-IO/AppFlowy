import 'package:appflowy/user/application/user_listener.dart';
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
    final UserProfilePB user,
    final WorkspaceSettingPB workspaceSetting,
  )   : _listener = UserWorkspaceListener(userProfile: user),
        super(HomeState.initial(workspaceSetting)) {
    on<HomeEvent>(
      (final event, final emit) async {
        await event.map(
          initial: (final _Initial value) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!isClosed) {
                add(HomeEvent.didReceiveWorkspaceSetting(workspaceSetting));
              }
            });

            _listener.start(
              onAuthChanged: (final result) => _authDidChanged(result),
              onSettingUpdated: (final result) {
                result.fold(
                  (final setting) =>
                      add(HomeEvent.didReceiveWorkspaceSetting(setting)),
                  (final r) => Log.error(r),
                );
              },
            );
          },
          showLoading: (final e) async {
            emit(state.copyWith(isLoading: e.isLoading));
          },
          didReceiveWorkspaceSetting: (final _DidReceiveWorkspaceSetting value) {
            final latestView = workspaceSetting.hasLatestView()
                ? workspaceSetting.latestView
                : state.latestView;

            emit(
              state.copyWith(
                workspaceSetting: value.setting,
                latestView: latestView,
              ),
            );
          },
          unauthorized: (final _Unauthorized value) {
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

  void _authDidChanged(final Either<Unit, FlowyError> errorOrNothing) {
    errorOrNothing.fold((final _) {}, (final error) {
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
  const factory HomeEvent.showLoading(final bool isLoading) = _ShowLoading;
  const factory HomeEvent.didReceiveWorkspaceSetting(
    final WorkspaceSettingPB setting,
  ) = _DidReceiveWorkspaceSetting;
  const factory HomeEvent.unauthorized(final String msg) = _Unauthorized;
}

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    required final bool isLoading,
    required final WorkspaceSettingPB workspaceSetting,
    final ViewPB? latestView,
    required final bool unauthorized,
  }) = _HomeState;

  factory HomeState.initial(final WorkspaceSettingPB workspaceSetting) => HomeState(
        isLoading: false,
        workspaceSetting: workspaceSetting,
        latestView: null,
        unauthorized: false,
      );
}
