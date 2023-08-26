import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/panes/panes_service.dart';
import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../panes.dart';

part 'panes_state.dart';

class PanesCubit extends Cubit<PanesState> {
  static final key = UniqueKey().toString();
  final PanesService panesService;
  late final MenuSharedState menuSharedState;
  PanesCubit()
      : panesService = PanesService(),
        menuSharedState = getIt<MenuSharedState>(),
        super(PanesState.initial());

  void setActivePane(PaneNode activePane) {
    emit(state.copyWith(activePane: activePane));
    _setLatestOpenView();
  }

  void splitRight(ViewPB view) {
    emit(
      state.copyWith(
        root: panesService.splitHandler(
          state.root,
          state.activePane.paneId,
          view,
          Direction.front,
          Axis.vertical,
        ),
      ),
    );
    emit(
      state.copyWith(
        count: panesService.countNodeHandler(
          state.root,
        ),
      ),
    );
  }

  void splitDown(ViewPB view) {
    emit(
      state.copyWith(
        root: panesService.splitHandler(
          state.root,
          state.activePane.paneId,
          view,
          Direction.front,
          Axis.horizontal,
        ),
      ),
    );
    emit(
      state.copyWith(
        count: panesService.countNodeHandler(
          state.root,
        ),
      ),
    );
  }

  void splitLeft(ViewPB view) {
    emit(
      state.copyWith(
        root: panesService.splitHandler(
          state.root,
          state.activePane.paneId,
          view,
          Direction.back,
          Axis.vertical,
        ),
      ),
    );
    emit(
      state.copyWith(
        count: panesService.countNodeHandler(
          state.root,
        ),
      ),
    );
  }

  void splitUp(ViewPB view) {
    emit(
      state.copyWith(
        root: panesService.splitHandler(
          state.root,
          state.activePane.paneId,
          view,
          Direction.back,
          Axis.horizontal,
        ),
      ),
    );
    emit(
      state.copyWith(
        count: panesService.countNodeHandler(
          state.root,
        ),
      ),
    );
  }

  void closePane(String paneId) {
    emit(
      state.copyWith(
        root: panesService.closePaneHandler(
          state.root,
          paneId,
          setActivePane,
        ),
      ),
    );
    emit(
      state.copyWith(
        count: panesService.countNodeHandler(
          state.root,
        ),
      ),
    );
  }

  void openTab({required Plugin plugin, required ViewPB view}) {
    state.activePane.tabs.openView(plugin, view);
    _setLatestOpenView();
  }

  void openPlugin({required Plugin plugin, ViewPB? view}) {
    state.activePane.tabs.openPlugin(plugin: plugin);
    _setLatestOpenView();
  }

  void selectTab({required int index, PaneNode? pane}) {
    if (pane != null) emit(state.copyWith(activePane: pane));
    state.activePane.tabs.selectTab(index: index);
    _setLatestOpenView();
  }

  void closeTab({required String pluginId, PaneNode? pane}) {
    if (pane != null) emit(state.copyWith(activePane: pane));
    state.activePane.tabs.closeView(pluginId);
    _setLatestOpenView();
  }

  void closeCurrentTab() {
    state.activePane.tabs.closeView(
      state.activePane.tabs.currentPageManager.plugin.id,
    );
    _setLatestOpenView();
  }

  void _setLatestOpenView([ViewPB? view]) {
    if (view != null) {
      menuSharedState.latestOpenView = view;
    } else {
      final pageManager = state.activePane.tabs.currentPageManager;
      final notifier = pageManager.plugin.notifier;
      if (notifier is ViewPluginNotifier) {
        menuSharedState.latestOpenView = notifier.view;
      }
    }
  }
}
