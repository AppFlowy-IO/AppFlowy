import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';
import 'package:appflowy/workspace/presentation/home/tabs/draggable_tab_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter/material.dart';

class Tabs extends ChangeNotifier {
  int currentIndex;
  List<PageManager> _pageManagers;
  int get pages => _pageManagers.length;
  PageManager get currentPageManager => _pageManagers[currentIndex];
  List<PageManager> get pageManagers => _pageManagers;
  final MenuSharedState menuSharedState;

  Tabs({this.currentIndex = 0, List<PageManager>? pageManagers})
      : _pageManagers = pageManagers ?? [PageManager()],
        menuSharedState = getIt<MenuSharedState>();

  void openView(Plugin plugin) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (!selectExistingPlugin) {
      _pageManagers.add(PageManager()..setPlugin(plugin));
    }
    currentIndex = _pageManagers.length - 1;

    setLatestOpenView();
    notifyListeners();
  }

  void closeView(String pluginId) {
    // Avoid closing the only open tab
    if (_pageManagers.length == 1) {
      return;
    }

    _pageManagers.removeWhere((pm) => pm.plugin.id == pluginId);

    /// If currentIndex is greater than the amount of allowed indices
    /// And the current selected tab isn't the first (index 0)
    ///   as currentIndex cannot be -1
    /// Then decrease currentIndex by 1
    currentIndex = currentIndex > _pageManagers.length - 1 && currentIndex > 0
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
    final index = _pageManagers.indexWhere((pm) => pm.plugin.id == id);
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
  void openPlugin({required Plugin plugin}) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (!selectExistingPlugin) {
      _pageManagers[currentIndex].setPlugin(plugin);
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

  void transferTab({required PageManager pm}) {
    final selectExistingPlugin = _selectPluginIfOpen(pm.plugin.id);

    if (!selectExistingPlugin) {
      _pageManagers.add(PageManager()..setPlugin(pm.plugin));
    }
    currentIndex = _pageManagers.length - 1;
    notifyListeners();
  }

  void move({
    required PageManager from,
    required PageManager to,
    required TabDraggableHoverPosition position,
  }) {
    pageManagers.remove(from);
    final selectExistingPlugin = _selectPluginIfOpen(from.plugin.id);

    if (!selectExistingPlugin) {
      switch (position) {
        case TabDraggableHoverPosition.none:
          return;
        case TabDraggableHoverPosition.left:
          {
            final index = pageManagers.indexOf(to);
            pageManagers.insert(
              index,
              from,
            );
            currentIndex = index;
            break;
          }
        case TabDraggableHoverPosition.right:
          {
            final index = pageManagers.indexOf(to);
            if (index + 1 == pageManagers.length) {
              pageManagers.add(from);
            } else {
              pageManagers.insert(index + 1, from);
            }
            currentIndex = index + 1;
            break;
          }
      }
    }
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
