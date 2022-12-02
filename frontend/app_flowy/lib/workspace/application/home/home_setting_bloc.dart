import 'package:app_flowy/user/application/user_listener.dart';
import 'package:app_flowy/workspace/application/edit_panel/edit_context.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/workspace.pb.dart'
    show WorkspaceSettingPB;
import 'package:flowy_sdk/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:dartz/dartz.dart';
part 'home_setting_bloc.freezed.dart';

class HomeSettingBloc extends Bloc<HomeSettingEvent, HomeSettingState> {
  final UserWorkspaceListener _listener;

  HomeSettingBloc(
    UserProfilePB user,
    WorkspaceSettingPB workspaceSetting,
  )   : _listener = UserWorkspaceListener(userProfile: user),
        super(HomeSettingState.initial(workspaceSetting)) {
    on<HomeSettingEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {},
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
          collapseMenu: (_CollapseMenu e) {
            emit(state.copyWith(isMenuCollapsed: !state.isMenuCollapsed));
          },
          editPanelResizeStart: (_EditPanelResizeStart e) {
            emit(state.copyWith(
              resizeType: MenuResizeType.drag,
              resizeStart: state.resizeOffset,
            ));
          },
          editPanelResized: (_EditPanelResized e) {
            final newPosition =
                (e.offset + state.resizeStart).clamp(-50, 200).toDouble();
            if (state.resizeOffset != newPosition) {
              emit(state.copyWith(resizeOffset: newPosition));
            }
          },
          editPanelResizeEnd: (_EditPanelResizeEnd e) {
            emit(state.copyWith(resizeType: MenuResizeType.slide));
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
class HomeSettingEvent with _$HomeSettingEvent {
  const factory HomeSettingEvent.initial() = _Initial;
  const factory HomeSettingEvent.forceCollapse(bool forceCollapse) =
      _ForceCollapse;
  const factory HomeSettingEvent.setEditPanel(EditPanelContext editContext) =
      _ShowEditPanel;
  const factory HomeSettingEvent.dismissEditPanel() = _DismissEditPanel;
  const factory HomeSettingEvent.didReceiveWorkspaceSetting(
      WorkspaceSettingPB setting) = _DidReceiveWorkspaceSetting;
  const factory HomeSettingEvent.collapseMenu() = _CollapseMenu;
  const factory HomeSettingEvent.editPanelResized(double offset) =
      _EditPanelResized;
  const factory HomeSettingEvent.editPanelResizeStart() = _EditPanelResizeStart;
  const factory HomeSettingEvent.editPanelResizeEnd() = _EditPanelResizeEnd;
}

@freezed
class HomeSettingState with _$HomeSettingState {
  const factory HomeSettingState({
    required bool forceCollapse,
    required Option<EditPanelContext> panelContext,
    required WorkspaceSettingPB workspaceSetting,
    required bool unauthorized,
    required bool isMenuCollapsed,
    required double resizeOffset,
    required double resizeStart,
    required MenuResizeType resizeType,
  }) = _HomeSettingState;

  factory HomeSettingState.initial(WorkspaceSettingPB workspaceSetting) =>
      HomeSettingState(
        forceCollapse: false,
        panelContext: none(),
        workspaceSetting: workspaceSetting,
        unauthorized: false,
        isMenuCollapsed: false,
        resizeOffset: 0,
        resizeStart: 0,
        resizeType: MenuResizeType.slide,
      );
}
