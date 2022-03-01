import 'package:app_flowy/plugin/plugin.dart';
import 'package:app_flowy/startup/tasks/load_plugin.dart';
import 'package:flowy_infra/notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/presentation/stack_page/home_stack.dart';
import 'package:app_flowy/workspace/presentation/widgets/prelude.dart';

typedef NavigationCallback = void Function(String id);

abstract class NavigationItem {
  Widget get leftBarItem;
  Widget? get rightBarItem => null;

  NavigationCallback get action => (id) {
        getIt<HomeStackManager>().setStackWithId(id);
      };
}

abstract class HomeStackContext<T> with NavigationItem {
  List<NavigationItem> get navigationItems;

  @override
  Widget get leftBarItem;

  @override
  Widget? get rightBarItem;

  ValueNotifier<T> get isUpdated;

  Widget buildWidget();

  void dispose();
}

class HomeStackNotifier extends ChangeNotifier {
  Plugin _plugin;
  PublishNotifier<bool> collapsedNotifier = PublishNotifier();

  Widget get titleWidget => _plugin.display.leftBarItem;

  HomeStackNotifier({Plugin? plugin}) : _plugin = plugin ?? makePlugin(pluginType: DefaultPlugin.blank.type());

  set plugin(Plugin newPlugin) {
    if (newPlugin.pluginId == _plugin.pluginId) {
      return;
    }

    // stackContext.isUpdated.removeListener(notifyListeners);
    _plugin.dispose();

    _plugin = newPlugin;
    // stackContext.isUpdated.addListener(notifyListeners);
    notifyListeners();
  }

  Plugin get plugin => _plugin;
}

// HomeStack is initialized as singleton to controll the page stack.
class HomeStackManager {
  final HomeStackNotifier _notifier = HomeStackNotifier();
  HomeStackManager();

  Widget title() {
    return _notifier.plugin.display.leftBarItem;
  }

  PublishNotifier<bool> get collapsedNotifier => _notifier.collapsedNotifier;

  void setPlugin(Plugin newPlugin) {
    _notifier.plugin = newPlugin;
  }

  void setStackWithId(String id) {}

  Widget stackTopBar() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _notifier),
      ],
      child: Selector<HomeStackNotifier, Widget>(
        selector: (context, notifier) => notifier.titleWidget,
        builder: (context, widget, child) {
          return const HomeTopBar();
        },
      ),
    );
  }

  Widget stackWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _notifier),
      ],
      child: Consumer(builder: (ctx, HomeStackNotifier notifier, child) {
        return FadingIndexedStack(
          index: getIt<PluginSandbox>().indexOf(notifier.plugin.pluginType),
          children: getIt<PluginSandbox>().supportPluginTypes.map((pluginType) {
            if (pluginType == notifier.plugin.pluginType) {
              return notifier.plugin.display.buildWidget();
            } else {
              return const BlankStackPage();
            }
          }).toList(),
        );
      }),
    );
  }
}
