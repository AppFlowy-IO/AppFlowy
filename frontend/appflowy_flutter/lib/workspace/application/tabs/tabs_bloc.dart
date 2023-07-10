import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'tabs_event.dart';
part 'tabs_state.dart';
part 'tabs_bloc.freezed.dart';

class TabsBloc extends Bloc<TabsEvent, TabsState> {
  late final MenuSharedState menuSharedState;

  TabsBloc() : super(TabsState()) {
    menuSharedState = getIt<MenuSharedState>();

    on<TabsEvent>((event, emit) async {
      event.when(
        selectTab: (int index) {
          if (index != state.currentIndex) {
            emit(state.copyWith(newIndex: index));
            _setLatestOpenView();
          }
        },
        moveTab: () {},
        closeTab: (String pluginId) {
          emit(state.closeView(pluginId));
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
    });
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
}
