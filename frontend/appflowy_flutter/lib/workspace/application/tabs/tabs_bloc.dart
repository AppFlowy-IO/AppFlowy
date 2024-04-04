import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tabs_bloc.freezed.dart';
part 'tabs_event.dart';
part 'tabs_state.dart';

class TabsBloc extends Bloc<TabsEvent, TabsState> {
  TabsBloc() : super(TabsState()) {
    menuSharedState = getIt<MenuSharedState>();
    _dispatch();
  }

  late final MenuSharedState menuSharedState;

  @override
  Future<void> close() {
    state.dispose();
    return super.close();
  }

  void _dispatch() {
    on<TabsEvent>(
      (event, emit) async {
        event.when(
          selectTab: (int index) {
            if (index != state.currentIndex &&
                index >= 0 &&
                index < state.pages) {
              emit(state.copyWith(newIndex: index));
              _setLatestOpenView();
            }
          },
          moveTab: () {},
          closeTab: (String pluginId) {
            emit(state.closeView(pluginId));
            _setLatestOpenView();
          },
          closeCurrentTab: () {
            emit(state.closeView(state.currentPageManager.plugin.id));
            _setLatestOpenView();
          },
          openTab: (Plugin plugin, ViewPB view) {
            emit(state.openView(plugin, view));
            _setLatestOpenView(view);
          },
          openPlugin: (Plugin plugin, ViewPB? view) {
            emit(state.openPlugin(plugin: plugin));
            _setLatestOpenView(view);
          },
        );
      },
    );
  }

  void _setLatestOpenView([ViewPB? view]) {
    if (view != null) {
      menuSharedState.latestOpenView = view;
    } else {
      final pageManager = state.currentPageManager;
      final notifier = pageManager.plugin.notifier;
      if (notifier is ViewPluginNotifier) {
        menuSharedState.latestOpenView = notifier.view;
      }
    }
  }

  /// Adds a [TabsEvent.openTab] event for the provided [ViewPB]
  void openTab(ViewPB view) =>
      add(TabsEvent.openTab(plugin: view.plugin(), view: view));

  /// Adds a [TabsEvent.openPlugin] event for the provided [ViewPB]
  void openPlugin(
    ViewPB view, {
    Map<String, dynamic> arguments = const {},
  }) =>
      add(
        TabsEvent.openPlugin(
          plugin: view.plugin(arguments: arguments),
          view: view,
        ),
      );
}
