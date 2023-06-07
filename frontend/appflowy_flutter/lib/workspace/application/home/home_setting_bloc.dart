import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/workspace/application/appearance.dart';
import 'package:appflowy/workspace/application/edit_panel/edit_context.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/workspace.pb.dart'
    show WorkspaceSettingPB;
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:dartz/dartz.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_setting_bloc.freezed.dart';

class HomeSettingBloc extends Bloc<HomeSettingEvent, HomeSettingState> {
  final UserWorkspaceListener _listener;
  final AppearanceSettingsCubit _appearanceSettingsCubit;

  HomeSettingBloc(
    UserProfilePB user,
    WorkspaceSettingPB workspaceSetting,
    AppearanceSettingsCubit appearanceSettingsCubit,
  )   : _listener = UserWorkspaceListener(userProfile: user),
        _appearanceSettingsCubit = appearanceSettingsCubit,
        super(
          HomeSettingState.initial(
            workspaceSetting,
            appearanceSettingsCubit.state,
          ),
        ) {
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
          didReceiveWorkspaceSetting: (_DidReceiveWorkspaceSetting value) {
            emit(state.copyWith(workspaceSetting: value.setting));
          },
          collapseMenu: (_CollapseMenu e) {
            final isMenuCollapsed = !state.isMenuCollapsed;
            _appearanceSettingsCubit.saveIsMenuCollapsed(isMenuCollapsed);
            emit(state.copyWith(isMenuCollapsed: isMenuCollapsed));
          },
          editPanelResizeStart: (_EditPanelResizeStart e) {
            emit(
              state.copyWith(
                resizeType: MenuResizeType.drag,
                resizeStart: state.resizeOffset,
              ),
            );
          },
          editPanelResized: (_EditPanelResized e) {
            final newPosition =
                (e.offset + state.resizeStart).clamp(-50, 200).toDouble();
            if (state.resizeOffset != newPosition) {
              emit(state.copyWith(resizeOffset: newPosition));
            }
          },
          editPanelResizeEnd: (_EditPanelResizeEnd e) {
            _appearanceSettingsCubit.saveMenuOffset(state.resizeOffset);
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
  const factory HomeSettingEvent.setEditPanel(EditPanelContext editContext) =
      _ShowEditPanel;
  const factory HomeSettingEvent.dismissEditPanel() = _DismissEditPanel;
  const factory HomeSettingEvent.didReceiveWorkspaceSetting(
    WorkspaceSettingPB setting,
  ) = _DidReceiveWorkspaceSetting;
  const factory HomeSettingEvent.collapseMenu() = _CollapseMenu;
  const factory HomeSettingEvent.editPanelResized(double offset) =
      _EditPanelResized;
  const factory HomeSettingEvent.editPanelResizeStart() = _EditPanelResizeStart;
  const factory HomeSettingEvent.editPanelResizeEnd() = _EditPanelResizeEnd;
}

@freezed
class HomeSettingState with _$HomeSettingState {
  const factory HomeSettingState({
    required Option<EditPanelContext> panelContext,
    required WorkspaceSettingPB workspaceSetting,
    required bool unauthorized,
    required bool isMenuCollapsed,
    required double resizeOffset,
    required double resizeStart,
    required MenuResizeType resizeType,
  }) = _HomeSettingState;

  factory HomeSettingState.initial(
    WorkspaceSettingPB workspaceSetting,
    AppearanceSettingsState appearanceSettingsState,
  ) =>
      HomeSettingState(
        panelContext: none(),
        workspaceSetting: workspaceSetting,
        unauthorized: false,
        isMenuCollapsed: appearanceSettingsState.isMenuCollapsed,
        resizeOffset: appearanceSettingsState.menuOffset,
        resizeStart: 0,
        resizeType: MenuResizeType.slide,
      );
}
