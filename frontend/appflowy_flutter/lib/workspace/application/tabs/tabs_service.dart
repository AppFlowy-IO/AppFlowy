import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_bloc/panes_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';

class TabService {
  TabService() : menuSharedState = getIt<MenuSharedState>();

  final MenuSharedState menuSharedState;

  PageManager? updateWriteStatusHandler(String pluginId, PaneNode node) {
    for (final page in node.tabsController.pageManagers) {
      if (page.plugin.id == pluginId && page.readOnly) {
        return page;
      }
    }

    for (int i = 0; i < node.children.length; i++) {
      final result = updateWriteStatusHandler(pluginId, node.children[i]);
      if (result != null) {
        return result..setReadOnlyStatus(false);
      }
    }
    return null;
  }

  void openViewHandler(
    TabsController controller,
    Plugin plugin, {
    int? index,
  }) {
    final openPlugins = menuSharedState.openPlugins;

    /// Determine placement of new pagemanager in list of pagemanagers
    final pageManager = PageManager()
      ..setPlugin(plugin)
      ..setReadOnlyStatus(openPlugins.containsKey(plugin.id));

    if (index == null || index >= controller.pageManagers.length) {
      controller.pageManagers.add(pageManager);
    } else {
      controller.pageManagers.insert(index, pageManager);
    }

    openPlugins.update(plugin.id, (value) => value + 1, ifAbsent: () => 1);
    menuSharedState.openPlugins = openPlugins;
  }

  void closeViewHandler(
    TabsController controller,
    String pluginId, {
    bool move = false,
  }) {
    final openPlugins = menuSharedState.openPlugins;
    final pm = controller.pageManagers.firstWhere(
      (pm) => pm.plugin.id == pluginId,
    );

    if (!pm.readOnly && openPlugins.containsKey(pluginId) && !move) {
      controller.tabService.updateWriteStatusHandler(
        pluginId,
        getIt<PanesBloc>().state.root,
      );
    }

    openPlugins.update(pluginId, (value) => value - 1);
    if (openPlugins[pluginId] == 0) {
      openPlugins.remove(pluginId);
    }

    menuSharedState.openPlugins = openPlugins;
    controller.pageManagers.removeWhere((pm) => pm.plugin.id == pluginId);
  }

  void openPluginHandler(
    TabsController controller,
    Plugin plugin,
  ) {
    final openPlugins = menuSharedState.openPlugins;
    final isPluginOpen = openPlugins.containsKey(plugin.id);
    final isCurrentPluginOpen = openPlugins.containsKey(
      controller.currentPageManager.plugin.id,
    );

    /// Check if a plugin similar to current plugin is already
    /// open in any other pane/tabs
    if (isCurrentPluginOpen) {
      /// If a similar plugin is open and current plugin is writable,
      /// then make some other plugin writable and sync data before
      /// currentPlugin is closed.
      if (!controller.currentPageManager.readOnly) {
        updateWriteStatusHandler(
          controller.currentPageManager.plugin.id,
          getIt<PanesBloc>().state.root,
        );
      }

      /// Update total count of open plugins having similar id as current plugin
      openPlugins.update(
        controller.currentPageManager.plugin.id,
        (value) => value - 1,
      );

      if (openPlugins[controller.currentPageManager.plugin.id] == 0) {
        openPlugins.remove(controller.currentPageManager.plugin.id);
      }
    }

    /// Create new pagemanager for passed plugin
    final pageManager = PageManager()
      ..setPlugin(plugin)
      ..setReadOnlyStatus(isPluginOpen);

    controller.currentPageManager = pageManager;

    /// Update total count of open views holding similar id as passed plugin
    openPlugins.update(plugin.id, (value) => value + 1, ifAbsent: () => 1);
    menuSharedState.openPlugins = openPlugins;
  }
}
