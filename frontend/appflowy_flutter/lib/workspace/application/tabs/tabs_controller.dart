import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/tabs/tabs_service.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/tabs/draggable_tab_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

class TabsController extends ChangeNotifier {
  int currentIndex;
  List<PageManager> pageManagers;
  int get pages => pageManagers.length;
  PageManager get currentPageManager => pageManagers[currentIndex];
  final MenuSharedState menuSharedState;

  TabsController({int? currentIndex, List<PageManager>? pageManagers})
      : pageManagers = pageManagers ?? [PageManager()],
        menuSharedState = getIt<MenuSharedState>(),
        currentIndex = currentIndex ?? 0;

  Future<void> closeAllViews() async {
    for (final page in pageManagers) {
      closeView(page.plugin.id, closePaneSubRoutine: true);
    }
  }

  void openView(Plugin plugin) async {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (!selectExistingPlugin) {
      final readOnly = await TabsService.setPluginOpenedInCache(plugin);
      pageManagers.add(PageManager()
        ..setPlugin(plugin)
        ..setReadOnlyStatus(readOnly));
    }
    currentIndex = pageManagers.length - 1;

    setLatestOpenView();
    notifyListeners();
  }

  void closeView(String pluginId, {bool? closePaneSubRoutine}) async {
    // Avoid closing the only open tab
    if (pageManagers.length == 1) {
      if (closePaneSubRoutine ?? false) {
        await TabsService.setPluginClosedInCache(pluginId);
      }
      return;
    }
    await TabsService.setPluginClosedInCache(pluginId);
    pageManagers.removeWhere((pm) => pm.plugin.id == pluginId);

    /// If currentIndex is greater than the amount of allowed indices
    /// And the current selected tab isn't the first (index 0)
    ///   as currentIndex cannot be -1
    /// Then decrease currentIndex by 1
    currentIndex = currentIndex > pageManagers.length - 1 && currentIndex > 0
        ? currentIndex - 1
        : currentIndex;

    setLatestOpenView();
    notifyListeners();
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
  void openPlugin({required Plugin plugin}) async {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (!selectExistingPlugin) {
      await TabsService.setPluginClosedInCache(currentPageManager.plugin.id);
      final readOnly = await TabsService.setPluginOpenedInCache(plugin);
      pageManagers[currentIndex]
        ..setPlugin(plugin)
        ..setReadOnlyStatus(readOnly);
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
      final readOnly = await TabsService.setPluginOpenedInCache(from.plugin);
      final newPm = PageManager()
        ..setPlugin(from.plugin)
        ..setReadOnlyStatus(readOnly);
      switch (position) {
        case TabDraggableHoverPosition.none:
          return;
        case TabDraggableHoverPosition.left:
          {
            final index = pageManagers.indexOf(to);
            pageManagers.insert(index, newPm);
            currentIndex = index;
            break;
          }
        case TabDraggableHoverPosition.right:
          {
            final index = pageManagers.indexOf(to);
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
}
