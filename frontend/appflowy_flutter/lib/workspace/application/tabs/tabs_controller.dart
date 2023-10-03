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
  final String encoding;

  TabsController({
    int? currentIndex,
    List<PageManager>? pageManagers,
    required this.encoding,
  })  : pageManagers = pageManagers ?? [PageManager("${encoding}0")],
        menuSharedState = getIt<MenuSharedState>(),
        currentIndex = currentIndex ?? 0;

  void closeAllViews() {
    final pageManagersCopy = List<PageManager>.from(pageManagers);
    for (final page in pageManagersCopy) {
      closeView(page.plugin.id, closePaneSubRoutine: true);
    }
    pageManagers = pageManagersCopy;
    notifyListeners();
  }

  void openView(Plugin plugin) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);
    final length = pageManagers.length;
    if (!selectExistingPlugin) {
      // check if view is already open
      final openPlugins = menuSharedState.openPlugins;
      if (openPlugins.containsKey(plugin.id)) {
        pageManagers.add(PageManager("$encoding$length")
          ..setPlugin(plugin)
          ..setReadOnlyStatus(true));
      } else {
        pageManagers.add(PageManager("$menuSharedState$length")
          ..setPlugin(plugin)
          ..setReadOnlyStatus(false));
      }
      openPlugins[plugin.id] = [...?openPlugins[plugin.id], "$encoding$length"];
      menuSharedState.openPlugins = openPlugins;
    }
    currentIndex = pageManagers.length - 1;

    setLatestOpenView();
    notifyListeners();
  }

  void closeView(
    String pluginId, {
    bool closePaneSubRoutine = false,
  }) async {
    // Avoid closing the only open tab unless it is part of subroutine to close pane
    if (pageManagers.length == 1 && (!closePaneSubRoutine)) {
      return;
    }
    final openPlugins = menuSharedState.openPlugins;
    final pm = pageManagers.firstWhere((pm) {
      return pm.plugin.id == pluginId;
    });

    openPlugins.update(
      pluginId,
      (value) => value..remove(pm.notifier.position),
    );

    if (openPlugins[pluginId]?.isEmpty ?? false) {
      openPlugins.remove(pluginId);
    }

    if (!pm.readOnly && openPlugins.containsKey(pluginId)) {
      final newPath = openPlugins[pluginId]!.first;
      Log.warn(
        "New path is $newPath navigate to here in tree, sync and remove readOnly",
      );
      _getPluginOnPath(
        newPath,
        getIt<PanesCubit>().state.root,
        1,
      ).setReadOnlyStatus(false);
    }

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
  void openPlugin({required Plugin plugin, bool newPane = false}) async {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (!selectExistingPlugin) {
      final openPlugins = menuSharedState.openPlugins;
      //remove current plugin path from state store
      if (openPlugins.containsKey(plugin.id)) {
        openPlugins.update(
          plugin.id,
          (value) =>
              value..remove(pageManagers[currentIndex].notifier.position),
        );
      }
      if (openPlugins.containsKey(plugin.id)) {
        pageManagers[currentIndex]
          ..setPlugin(plugin)
          ..setReadOnlyStatus(true);
      } else {
        pageManagers[currentIndex]
          ..setPlugin(plugin)
          ..setReadOnlyStatus(false);
      }
      openPlugins[plugin.id] = [
        ...?openPlugins[plugin.id],
        "$encoding$currentIndex",
      ];
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
  }) async {
    final selectExistingPlugin = _selectPluginIfOpen(from.plugin.id);

    if (!selectExistingPlugin) {
      switch (position) {
        case TabDraggableHoverPosition.none:
          return;
        case TabDraggableHoverPosition.left:
          {
            final index = pageManagers.indexOf(to);
            final newPm = PageManager("$encoding$index")
              ..setPlugin(from.plugin);
            pageManagers.insert(index, newPm);
            currentIndex = index;
            break;
          }
        case TabDraggableHoverPosition.right:
          {
            final index = pageManagers.indexOf(to);
            final newPm = PageManager("$encoding${index + 1}")
              ..setPlugin(from.plugin);
            if (index + 1 == pageManagers.length) {
              pageManagers.add(newPm);
            } else {
              pageManagers.insert(index + 1, newPm);
            }
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

  PageManager _getPluginOnPath(String encoding, PaneNode node, int index) {
    if (index == encoding.length - 2) {
      return node.tabs.pageManagers[int.parse(encoding[encoding.length - 1])];
    }

    return _getPluginOnPath(
      encoding,
      node.children[int.parse(encoding[index])],
      index + 1,
    );
  }
}
