import 'package:appflowy/user/application/user_listener.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart'
    show WorkspaceSettingPB;
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final UserWorkspaceListener _workspaceListener;

  HomeBloc(
    UserProfilePB user,
    WorkspaceSettingPB workspaceSetting,
  )   : _workspaceListener = UserWorkspaceListener(userProfile: user),
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

            _workspaceListener.start(
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

            emit(
              state.copyWith(
                workspaceSetting: value.setting,
                latestView: latestView,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Future<void> close() async {
    await _workspaceListener.stop();
    return super.close();
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
    WorkspaceSettingPB setting,
  ) = _DidReceiveWorkspaceSetting;
}

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    required bool isLoading,
    required WorkspaceSettingPB workspaceSetting,
    ViewPB? latestView,
  }) = _HomeState;

  factory HomeState.initial(WorkspaceSettingPB workspaceSetting) => HomeState(
        isLoading: false,
        workspaceSetting: workspaceSetting,
        latestView: null,
      );
}
