import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/tabs/draggable_tab_item.dart';
import 'package:appflowy_backend/log.dart';

import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

class TabsController extends ChangeNotifier {
  int currentIndex;
  List<PageManager> pageManagers;
  int get pages => pageManagers.length;
  PageManager get currentPageManager => pageManagers[currentIndex];
  final MenuSharedState menuSharedState;
  TabsController({
    int? currentIndex,
    List<PageManager>? pageManagers,
  })  : pageManagers = pageManagers ?? [PageManager()],
        menuSharedState = getIt<MenuSharedState>(),
        currentIndex = currentIndex ?? 0;

  bool _dispose = false;

  @override
  void notifyListeners() {
    if (!_dispose) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    if (!_dispose) {
      super.dispose();
    }
    _dispose = true;
  }

  void closeAllViews() {
    final pageManagersCopy = List<PageManager>.from(pageManagers);
    for (final page in pageManagersCopy) {
      closeView(page.plugin.id, closePaneSubRoutine: true);
    }
    pageManagers = pageManagersCopy;
  }

  void openView(Plugin plugin) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);
    if (!selectExistingPlugin) {
      // check if view is already open
      final openPlugins = menuSharedState.openPlugins;

      if (openPlugins.containsKey(plugin.id)) {
        pageManagers.add(PageManager()
          ..setPlugin(plugin)
          ..setReadOnlyStatus(true));
      } else {
        pageManagers.add(PageManager()
          ..setPlugin(plugin)
          ..setReadOnlyStatus(false));
      }
      openPlugins.update(
        plugin.id,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      menuSharedState.openPlugins = openPlugins;
    }
    currentIndex = pageManagers.length - 1;

    setLatestOpenView();
    notifyListeners();
  }

  void closeView(
    String pluginId, {
    bool closePaneSubRoutine = false,
    bool move = false,
  }) {
    // Avoid closing the only open tab unless it is part of subroutine to close pane
    if (pageManagers.length == 1 && (!closePaneSubRoutine)) {
      return;
    }
    final openPlugins = menuSharedState.openPlugins;
    final pm = pageManagers.firstWhere((pm) {
      return pm.plugin.id == pluginId;
    });

    if (!pm.readOnly && openPlugins.containsKey(pluginId) && !move) {
      _updateWriteStatus(
        pluginId,
        getIt<PanesCubit>().state.root,
      )?.setReadOnlyStatus(false);
    }

    openPlugins.update(
      pluginId,
      (value) => value - 1,
    );

    if (openPlugins[pluginId] == 0) {
      openPlugins.remove(pluginId);
    }
    menuSharedState.openPlugins = openPlugins;
    pageManagers.removeWhere((pm) => pm.plugin.id == pluginId);

    /// If currentIndex is greater than the amount of allowed indices
    /// And the current selected tab isn't the first (index 0)
    ///   as currentIndex cannot be -1
    /// Then decrease currentIndex by 1
    currentIndex = currentIndex > pageManagers.length - 1 && currentIndex > 0
        ? currentIndex - 1
        : currentIndex;

    if (!closePaneSubRoutine) {
      setLatestOpenView();
      notifyListeners();
    }
  }

  /// Checks if a [Plugin.id] is already associated with an open tab.
  /// Returns a [TabState] with new index if there is a match.
  ///
  /// If no match it returns null
  ///
  bool _selectPluginIfOpen(String id) {
    final index = pageManagers.indexWhere((pm) => pm.plugin.id == id);
    if (index == -1) {
      return false;
    }
    currentIndex = index;
    notifyListeners();
    return true;
  }

  /// This opens a plugin in the current selected tab,
  /// due to how Document currently works, only one tab
  /// per plugin can currently be active.
  ///
  /// If the plugin is already open in a tab, then that tab
  /// will become selected.
  ///
  void openPlugin({
    required Plugin plugin,
    bool newPane = false,
    int? index,
  }) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (!selectExistingPlugin) {
      final openPlugins = menuSharedState.openPlugins;
      //remove current plugin path from state store

      if (openPlugins.containsKey(plugin.id)) {
        if (index != null) {
          if (index >= pageManagers.length) {
            pageManagers.add(PageManager()
              ..setPlugin(plugin)
              ..setReadOnlyStatus(true));
          } else {
            pageManagers.insert(
                index,
                PageManager()
                  ..setPlugin(plugin)
                  ..setReadOnlyStatus(true));
          }
        } else {
          if (openPlugins.containsKey(pageManagers[currentIndex].plugin.id)) {
            openPlugins.update(
                pageManagers[currentIndex].plugin.id, (value) => value - 1);

            if (openPlugins[pageManagers[currentIndex].plugin.id] == 0) {
              openPlugins.remove(pageManagers[currentIndex].plugin.id);
            }
          }
          pageManagers[currentIndex]
            ..setPlugin(plugin)
            ..setReadOnlyStatus(true);
        }
      } else {
        if (index != null) {
          if (index >= pageManagers.length) {
            pageManagers.add(PageManager()
              ..setPlugin(plugin)
              ..setReadOnlyStatus(false));
          } else {
            pageManagers.insert(
                index,
                PageManager()
                  ..setPlugin(plugin)
                  ..setReadOnlyStatus(false));
          }
        } else {
          if (openPlugins.containsKey(pageManagers[currentIndex].plugin.id)) {
            openPlugins.update(
                pageManagers[currentIndex].plugin.id, (value) => value - 1);

            if (openPlugins[pageManagers[currentIndex].plugin.id] == 0) {
              openPlugins.remove(pageManagers[currentIndex].plugin.id);
            }
          }
          pageManagers[currentIndex]
            ..setPlugin(plugin)
            ..setReadOnlyStatus(false);
        }
      }
      openPlugins.update(
        plugin.id,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
      menuSharedState.openPlugins = openPlugins;
    }
    setLatestOpenView();
    notifyListeners();
  }

  void selectTab({required int index}) {
    if (index != currentIndex && index >= 0 && index < pages) {
      currentIndex = index;
      setLatestOpenView();
      notifyListeners();
    }
  }

  void move({
    required PageManager from,
    required PageManager to,
    required TabDraggableHoverPosition position,
  }) {
    final selectExistingPlugin = _selectPluginIfOpen(from.plugin.id);

    if (!selectExistingPlugin) {
      switch (position) {
        case TabDraggableHoverPosition.none:
          return;
        case TabDraggableHoverPosition.left:
          {
            final index = pageManagers.indexOf(to);
            openPlugin(plugin: from.plugin, index: index);
            currentIndex = index;
            break;
          }
        case TabDraggableHoverPosition.right:
          {
            final index = pageManagers.indexOf(to);
            openPlugin(plugin: from.plugin, index: index);
            currentIndex = index + 1;
            break;
          }
      }
    }
    setLatestOpenView();
    notifyListeners();
  }

  void setLatestOpenView([ViewPB? view]) {
    if (view != null) {
      menuSharedState.latestOpenView = view;
    } else {
      final notifier = currentPageManager.plugin.notifier;
      if (notifier is ViewPluginNotifier) {
        menuSharedState.latestOpenView = notifier.view;
      }
    }
  }

  PageManager? _updateWriteStatus(String pluginId, PaneNode node) {
    for (final page in node.tabs.pageManagers) {
      Log.warn(page.plugin.id);
      if (page.plugin.id == pluginId && page.readOnly) {
        return page;
      }
    }
    for (int i = 0; i < node.children.length; i++) {
      final result = _updateWriteStatus(pluginId, node.children[i]);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}
