import 'package:app_flowy/user/application/user_listener.dart';
import 'package:app_flowy/workspace/application/edit_panel/edit_context.dart';
import 'package:flowy_sdk/log.dart';
import 'package:flowy_sdk/protobuf/flowy-error-code/code.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-error/errors.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart'
    show CurrentWorkspaceSettingPB;
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
part 'home_bloc.freezed.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final UserWorkspaceListener _listener;

  HomeBloc(UserProfilePB user, CurrentWorkspaceSettingPB workspaceSetting)
      : _listener = UserWorkspaceListener(userProfile: user),
        super(HomeState.initial(workspaceSetting)) {
    on<HomeEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {
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
          setEditPanel: (e) async {
            emit(state.copyWith(panelContext: some(e.editContext)));
          },
          dismissEditPanel: (value) async {
            emit(state.copyWith(panelContext: none()));
          },
          forceCollapse: (e) async {
            emit(state.copyWith(forceCollapse: e.forceCollapse));
          },
          didReceiveWorkspaceSetting: (_DidReceiveWorkspaceSetting value) {
            emit(state.copyWith(workspaceSetting: value.setting));
          },
          unauthorized: (_Unauthorized value) {
            emit(state.copyWith(unauthorized: true));
          },
          collapseMenu: (e) {
            emit(state.copyWith(isMenuCollapsed: !state.isMenuCollapsed));
          },
          editPanelResized: (e) {
            final newOffset =
                (state.resizeOffset + e.offset).clamp(-50, 200).toDouble();
            emit(state.copyWith(resizeOffset: newOffset));
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

@freezed
class HomeEvent with _$HomeEvent {
  const factory HomeEvent.initial() = _Initial;
  const factory HomeEvent.showLoading(bool isLoading) = _ShowLoading;
  const factory HomeEvent.forceCollapse(bool forceCollapse) = _ForceCollapse;
  const factory HomeEvent.setEditPanel(EditPanelContext editContext) =
      _ShowEditPanel;
  const factory HomeEvent.dismissEditPanel() = _DismissEditPanel;
  const factory HomeEvent.didReceiveWorkspaceSetting(
      CurrentWorkspaceSettingPB setting) = _DidReceiveWorkspaceSetting;
  const factory HomeEvent.unauthorized(String msg) = _Unauthorized;
  const factory HomeEvent.collapseMenu() = _CollapseMenu;
  const factory HomeEvent.editPanelResized(double offset) = _EditPanelResized;
}

@freezed
class HomeState with _$HomeState {
  const factory HomeState({
    required bool isLoading,
    required bool forceCollapse,
    required Option<EditPanelContext> panelContext,
    required CurrentWorkspaceSettingPB workspaceSetting,
    required bool unauthorized,
    required bool isMenuCollapsed,
    required double resizeOffset,
  }) = _HomeState;

  factory HomeState.initial(CurrentWorkspaceSettingPB workspaceSetting) =>
      HomeState(
        isLoading: false,
        forceCollapse: false,
        panelContext: none(),
        workspaceSetting: workspaceSetting,
        unauthorized: false,
        isMenuCollapsed: false,
        resizeOffset: 0,
      );
}
