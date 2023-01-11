import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/blank/blank.dart';
import 'package:app_flowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:time/time.dart';
import 'package:app_flowy/startup/plugin/plugin.dart';
import 'package:app_flowy/workspace/presentation/home/home_sizes.dart';
import 'package:app_flowy/workspace/presentation/home/navigation.dart';
import 'package:app_flowy/core/frameless_window.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flowy_infra/notifier.dart';
import 'home_layout.dart';

typedef NavigationCallback = void Function(String id);

abstract class HomeStackDelegate {
  void didDeleteStackWidget(ViewPB view, int? index);
}

class HomeStack extends StatelessWidget {
  final HomeStackDelegate delegate;
  final HomeLayout layout;
  const HomeStack({
    required this.delegate,
    required this.layout,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        getIt<HomeStackManager>().stackTopBar(layout: layout),
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: FocusTraversalGroup(
              child: getIt<HomeStackManager>().stackWidget(
                onDeleted: (view, index) {
                  delegate.didDeleteStackWidget(view, index);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FadingIndexedStack extends StatefulWidget {
  final int index;
  final List<Widget> children;
  final Duration duration;

  const FadingIndexedStack({
    Key? key,
    required this.index,
    required this.children,
    this.duration = const Duration(
      milliseconds: 250,
    ),
  }) : super(key: key);

  @override
  FadingIndexedStackState createState() => FadingIndexedStackState();
}

class FadingIndexedStackState extends State<FadingIndexedStack> {
  double _targetOpacity = 1;

  @override
  void initState() {
    super.initState();
    initToastWithContext(context);
  }

  @override
  void didUpdateWidget(FadingIndexedStack oldWidget) {
    if (oldWidget.index == widget.index) return;
    setState(() => _targetOpacity = 0);
    Future.delayed(1.milliseconds, () => setState(() => _targetOpacity = 1));
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: _targetOpacity > 0 ? widget.duration : 0.milliseconds,
      tween: Tween(begin: 0, end: _targetOpacity),
      builder: (_, value, child) {
        return Opacity(opacity: value, child: child);
      },
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}

abstract class NavigationItem {
  Widget get leftBarItem;
  Widget? get rightBarItem => null;

  NavigationCallback get action => (id) {
        getIt<HomeStackManager>().setStackWithId(id);
      };
}

class HomeStackNotifier extends ChangeNotifier {
  Plugin _plugin;
  PublishNotifier<bool> collapsedNotifier = PublishNotifier();

  Widget get titleWidget => _plugin.display.leftBarItem;

  HomeStackNotifier({Plugin? plugin})
      : _plugin = plugin ?? makePlugin(pluginType: PluginType.blank);

  set plugin(Plugin newPlugin) {
    if (newPlugin.id == _plugin.id) {
      return;
    }

    _plugin.notifier?.isDisplayChanged.addListener(notifyListeners);
    _plugin.dispose();

    _plugin = newPlugin;
    _plugin.notifier?.isDisplayChanged.removeListener(notifyListeners);
    notifyListeners();
  }

  Plugin get plugin => _plugin;
}

// HomeStack is initialized as singleton to control the page stack.
class HomeStackManager {
  final HomeStackNotifier _notifier = HomeStackNotifier();
  HomeStackManager();

  Widget title() {
    return _notifier.plugin.display.leftBarItem;
  }

  PublishNotifier<bool> get collapsedNotifier => _notifier.collapsedNotifier;
  Plugin get plugin => _notifier.plugin;

  void setPlugin(Plugin newPlugin) {
    _notifier.plugin = newPlugin;
  }

  void setStackWithId(String id) {
    // Navigate to the page with id
  }

  Widget stackTopBar({required HomeLayout layout}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _notifier),
      ],
      child: Selector<HomeStackNotifier, Widget>(
        selector: (context, notifier) => notifier.titleWidget,
        builder: (context, widget, child) {
          return MoveWindowDetector(child: HomeTopBar(layout: layout));
        },
      ),
    );
  }

  Widget stackWidget({required Function(ViewPB, int?) onDeleted}) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _notifier)],
      child: Consumer(builder: (ctx, HomeStackNotifier notifier, child) {
        return FadingIndexedStack(
          index: getIt<PluginSandbox>().indexOf(notifier.plugin.ty),
          children: getIt<PluginSandbox>().supportPluginTypes.map((pluginType) {
            if (pluginType == notifier.plugin.ty) {
              return notifier.plugin.display
                  .buildWidget(PluginContext(onDeleted: onDeleted))
                  .padding(horizontal: 40, vertical: 28);
            } else {
              return const BlankPage();
            }
          }).toList(),
        );
      }),
    );
  }
}

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({Key? key, required this.layout}) : super(key: key);

  final HomeLayout layout;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      height: HomeSizes.topBarHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          HSpace(layout.menuSpacing),
          const FlowyNavigation(),
          const HSpace(16),
          ChangeNotifierProvider.value(
            value: Provider.of<HomeStackNotifier>(context, listen: false),
            child: Consumer(
              builder: (BuildContext context, HomeStackNotifier notifier,
                  Widget? child) {
                return notifier.plugin.display.rightBarItem ?? const SizedBox();
              },
            ),
          ) // _renderMoreButton(),
        ],
      )
          .padding(
            horizontal: HomeInsets.topBarTitlePadding,
          )
          .bottomBorder(color: Theme.of(context).dividerColor),
    );
  }
}
