import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/tabs/tabs_service.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/tabs/draggable_tab_item.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:nanoid/nanoid.dart';

class TabsController extends ChangeNotifier {
  TabsController({
    int? currentIndex,
    List<PageManager>? pageManagers,
  })  : pageManagers = pageManagers ?? [PageManager()],
        currentIndex = currentIndex ?? 0,
        tabId = nanoid();

  final TabService tabService = TabService();
  final String tabId;
  int currentIndex;
  List<PageManager> pageManagers;

  factory TabsController.reconstruct(TabsController oldController) {
    oldController.dispose();
    return TabsController(
      currentIndex: oldController.currentIndex,
      pageManagers: oldController.pageManagers,
    );
  }

  bool _dispose = false;
  int get pages => pageManagers.length;
  PageManager get currentPageManager => pageManagers[currentIndex];
  set currentPageManager(PageManager pm) => pageManagers[currentIndex] = pm;

  void closeAllViews() {
    final pageManagersCopy = List<PageManager>.from(pageManagers);
    for (final page in pageManagersCopy) {
      closeView(page.plugin.id, closePaneSubRoutine: true);
    }
    pageManagers = pageManagersCopy;
  }

  void openView(
    Plugin plugin, {
    int? index,
  }) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);
    if (!selectExistingPlugin) {
      tabService.openViewHandler(
        this,
        plugin,
        index: index,
      );
      currentIndex = index ?? pageManagers.length - 1;
    }

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

    tabService.closeViewHandler(this, pluginId, move: move);

    /// If currentIndex is greater than the amount of allowed indices
    /// And the current selected tab isn't the first (index 0)
    ///   as currentIndex cannot be -1
    /// Then decrease currentIndex by 1
    currentIndex = currentIndex > pageManagers.length - 1 && currentIndex > 0 ? currentIndex - 1 : currentIndex;

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
  void openPlugin({required Plugin plugin}) {
    final selectExistingPlugin = _selectPluginIfOpen(plugin.id);

    if (!selectExistingPlugin) {
      tabService.openPluginHandler(this, plugin);
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
    switch (position) {
      case TabDraggableHoverPosition.none:
        break;
      case TabDraggableHoverPosition.left:
        final index = pageManagers.indexOf(to);
        openView(
          from.plugin,
          index: index,
        );
        currentIndex = index;
        break;
      case TabDraggableHoverPosition.right:
        final index = pageManagers.indexOf(to);
        openView(
          from.plugin,
          index: index + 1,
        );
        currentIndex = index + 1;
        break;
    }
    setLatestOpenView();
    notifyListeners();
  }

  void setLatestOpenView([ViewPB? view]) {
    if (view != null) {
      tabService.menuSharedState.latestOpenView = view;
    } else {
      final notifier = currentPageManager.plugin.notifier;
      if (notifier is ViewPluginNotifier && !currentPageManager.readOnly) {
        tabService.menuSharedState.latestOpenView = notifier.view;
      }
    }
  }

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
}
