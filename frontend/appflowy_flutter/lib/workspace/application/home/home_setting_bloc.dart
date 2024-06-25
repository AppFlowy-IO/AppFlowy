import 'package:appflowy/user/application/user_listener.dart';
import 'package:appflowy/workspace/application/edit_panel/edit_context.dart';
import 'package:appflowy/workspace/application/settings/appearance/appearance_cubit.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/workspace.pb.dart'
    show WorkspaceSettingPB;
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/time/duration.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'home_setting_bloc.freezed.dart';

class HomeSettingBloc extends Bloc<HomeSettingEvent, HomeSettingState> {
  HomeSettingBloc(
    WorkspaceSettingPB workspaceSetting,
    AppearanceSettingsCubit appearanceSettingsCubit,
    double screenWidthPx,
  )   : _listener = FolderListener(),
        _appearanceSettingsCubit = appearanceSettingsCubit,
        super(
          HomeSettingState.initial(
            workspaceSetting,
            appearanceSettingsCubit.state,
            screenWidthPx,
          ),
        ) {
    _dispatch();
  }

  final FolderListener _listener;
  final AppearanceSettingsCubit _appearanceSettingsCubit;

  @override
  Future<void> close() async {
    await _listener.stop();
    return super.close();
  }

  void _dispatch() {
    on<HomeSettingEvent>(
      (event, emit) async {
        await event.map(
          initial: (_Initial value) {},
          setEditPanel: (e) async {
            emit(state.copyWith(panelContext: e.editContext));
          },
          dismissEditPanel: (value) async {
            emit(state.copyWith(panelContext: null));
          },
          didReceiveWorkspaceSetting: (_DidReceiveWorkspaceSetting value) {
            emit(state.copyWith(workspaceSetting: value.setting));
          },
          collapseMenu: (_CollapseMenu e) {
            final isMenuCollapsed = !state.isMenuCollapsed;
            _appearanceSettingsCubit.saveIsMenuCollapsed(isMenuCollapsed);
            emit(
              state.copyWith(
                isMenuCollapsed: isMenuCollapsed,
                keepMenuCollapsed: isMenuCollapsed,
              ),
            );
          },
          checkScreenSize: (_CheckScreenSize e) {
            final bool isScreenSmall =
                e.screenWidthPx < PageBreaks.tabletLandscape;

            if (state.isScreenSmall != isScreenSmall) {
              final isMenuCollapsed = isScreenSmall || state.keepMenuCollapsed;
              emit(
                state.copyWith(
                  isMenuCollapsed: isMenuCollapsed,
                  isScreenSmall: isScreenSmall,
                ),
              );
            } else {
              emit(state.copyWith(isScreenSmall: isScreenSmall));
            }
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
  const factory HomeSettingEvent.checkScreenSize(double screenWidthPx) =
      _CheckScreenSize;
  const factory HomeSettingEvent.editPanelResized(double offset) =
      _EditPanelResized;
  const factory HomeSettingEvent.editPanelResizeStart() = _EditPanelResizeStart;
  const factory HomeSettingEvent.editPanelResizeEnd() = _EditPanelResizeEnd;
}

@freezed
class HomeSettingState with _$HomeSettingState {
  const factory HomeSettingState({
    required EditPanelContext? panelContext,
    required WorkspaceSettingPB workspaceSetting,
    required bool unauthorized,
    required bool isMenuCollapsed,
    required bool keepMenuCollapsed,
    required bool isScreenSmall,
    required double resizeOffset,
    required double resizeStart,
    required MenuResizeType resizeType,
  }) = _HomeSettingState;

  factory HomeSettingState.initial(
    WorkspaceSettingPB workspaceSetting,
    AppearanceSettingsState appearanceSettingsState,
    double screenWidthPx,
  ) {
    return HomeSettingState(
      panelContext: null,
      workspaceSetting: workspaceSetting,
      unauthorized: false,
      isMenuCollapsed: appearanceSettingsState.isMenuCollapsed,
      isScreenSmall: screenWidthPx < PageBreaks.tabletLandscape,
      keepMenuCollapsed: false,
      resizeOffset: appearanceSettingsState.menuOffset,
      resizeStart: 0,
      resizeType: MenuResizeType.slide,
    );
  }
}
