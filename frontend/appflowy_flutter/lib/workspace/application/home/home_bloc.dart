import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart'
    show WorkspaceSettingPB;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(WorkspaceSettingPB workspaceSetting)
      : _workspaceListener = UserWorkspaceListener(),
        super(HomeState.initial(workspaceSetting)) {
    _dispatch(workspaceSetting);
  }

  final UserWorkspaceListener _workspaceListener;

  @override
  Future<void> close() async {
    await _workspaceListener.stop();
    return super.close();
  }

  void _dispatch(WorkspaceSettingPB workspaceSetting) {
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
            final latestView = value.setting.hasLatestView()
                ? value.setting.latestView
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
      );
}
