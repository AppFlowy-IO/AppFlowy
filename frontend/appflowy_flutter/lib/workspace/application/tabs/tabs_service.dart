import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/tabs/tabs_controller.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/home/menu/menu_shared_state.dart';

class TabService {
  final MenuSharedState menuSharedState;

  TabService() : menuSharedState = getIt<MenuSharedState>();

  PageManager? updateWriteStatusHandler(String pluginId, PaneNode node) {
    for (final page in node.tabs.pageManagers) {
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

  void openViewHandler(TabsController controller, Plugin plugin, {int? index}) {
    final openPlugins = menuSharedState.openPlugins;

    ///determine placement of new pagemanager in list of pagemanagers
    final pageManager = PageManager()
      ..setPlugin(plugin)
      ..setReadOnlyStatus(openPlugins.containsKey(plugin.id));

    if (index == null || index >= controller.pageManagers.length) {
      controller.pageManagers.add(pageManager);
    } else {
      controller.pageManagers.insert(index, pageManager);
    }

    openPlugins.update(
      plugin.id,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    menuSharedState.openPlugins = openPlugins;
  }

  void closeViewHandler(
    TabsController controller,
    String pluginId, {
    bool move = false,
  }) {
    final openPlugins = menuSharedState.openPlugins;
    final pm = controller.pageManagers.firstWhere((pm) {
      return pm.plugin.id == pluginId;
    });

    if (!pm.readOnly && openPlugins.containsKey(pluginId) && !move) {
      controller.tabService.updateWriteStatusHandler(
        pluginId,
        getIt<PanesCubit>().state.root,
      );
    }

    openPlugins.update(
      pluginId,
      (value) => value - 1,
    );

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
    final isCurrentPluginOpen =
        openPlugins.containsKey(controller.currentPageManager.plugin.id);

    ///check if a plugin similar to current plugin is already open in any other pane/tabs
    if (isCurrentPluginOpen) {
      ///if a similar plugin is open and current plugin is writable, make some other plugin writable and sync data before currentPlugin is closed.
      if (!controller.currentPageManager.readOnly) {
        updateWriteStatusHandler(
          controller.currentPageManager.plugin.id,
          getIt<PanesCubit>().state.root,
        );
      }

      ///update total count of open plugins having similar id as current plugin
      openPlugins.update(
        controller.currentPageManager.plugin.id,
        (value) => value - 1,
      );

      if (openPlugins[controller.currentPageManager.plugin.id] == 0) {
        openPlugins.remove(controller.currentPageManager.plugin.id);
      }
    }

    ///create new pagemanager for passed plugin
    final pageManager = PageManager()
      ..setPlugin(plugin)
      ..setReadOnlyStatus(isPluginOpen);

    controller.currentPageManager = pageManager;

    ///update total count of open views holding similar id as passed plugin
    openPlugins.update(
      plugin.id,
      (value) => value + 1,
      ifAbsent: () => 1,
    );
    menuSharedState.openPlugins = openPlugins;
  }
}
