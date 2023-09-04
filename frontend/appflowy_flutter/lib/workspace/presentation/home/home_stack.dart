import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/plugins/blank/blank.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/application/panes/size_cubit/cubit/pane_size_cubit.dart';
import 'package:appflowy/workspace/application/tabs/tabs.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/navigation.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:time/time.dart';

import 'home_layout.dart';

typedef NavigationCallback = void Function(String id);

abstract class HomeStackDelegate {
  void didDeleteStackWidget(ViewPB view, int? index);
}

class HomeStack extends StatelessWidget {
  final HomeStackDelegate delegate;
  final HomeLayout layout;
  final PaneNode? paneNode;
  const HomeStack({
    required this.delegate,
    this.paneNode,
    required this.layout,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PanesCubit, PanesState>(
      builder: (context, state) {
        return _buildTabs(state.root, context);
      },
    );
  }

  Widget _buildTabs(PaneNode root, BuildContext context) {
    if (root.children.isEmpty) {
      final pageController = PageController();
      return ChangeNotifierProvider<Tabs>(
        create: (context) => root.tabs,
        child: Consumer<Tabs>(
          builder: (context, value, child) => GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              context.read<PanesCubit>().setActivePane(root);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                TabsManager(
                  pane: root,
                  pageController: pageController,
                  tabs: value,
                ),
                value.currentPageManager
                    .stackTopBar(layout: layout, paneId: root.paneId),
                Expanded(
                  child: PageView(
                    physics: const NeverScrollableScrollPhysics(),
                    controller: pageController,
                    children: value.pageManagers
                        .map(
                          (pm) => PageStack(
                            pageManager: pm,
                            delegate: delegate,
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      double distance = 0;
      return SizedBox(
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            key: ValueKey(root.paneId),
            children: [
              ...root.children.map((e) {
                //TODO(squidrye): move calculations out of presentation
                final childWidth = (root.axis == Axis.vertical
                        ? constraints.maxWidth
                        : constraints.maxHeight) /
                    root.children.length;
                final childLeft = distance * childWidth;
                distance++;
                return BlocProvider(
                  create: (context) => PaneSizeCubit(offset: childLeft),
                  child: BlocBuilder<PaneSizeCubit, PaneSizeState>(
                    builder: (context, state) {
                      return Stack(
                        children: [
                          _buildTabs(e, context)
                              .constrained(
                                animate: true,
                                width: MediaQuery.of(context).size.width,
                                height: MediaQuery.of(context).size.height,
                              )
                              .positioned(
                                left: root.axis == Axis.vertical
                                    ? state.resizeOffset
                                    : null,
                                top: root.axis == Axis.horizontal
                                    ? state.resizeOffset
                                    : null,
                              ),
                          MouseRegion(
                            cursor: root.axis == Axis.vertical
                                ? SystemMouseCursors.resizeLeftRight
                                : SystemMouseCursors.resizeUpDown,
                            child: GestureDetector(
                              dragStartBehavior: DragStartBehavior.down,
                              onHorizontalDragStart: (details) => context
                                  .read<PaneSizeCubit>()
                                  .editPanelResizeStart(),
                              onHorizontalDragUpdate: (details) => context
                                  .read<PaneSizeCubit>()
                                  .editPanelResized(
                                    root.axis == Axis.vertical
                                        ? details.localPosition.dx
                                        : details.localPosition.dy,
                                  ),
                              behavior: HitTestBehavior.translucent,
                              child: Container(
                                color: Colors.lightBlue,
                                width: root.axis == Axis.vertical
                                    ? 5
                                    : MediaQuery.of(context).size.width,
                                height: root.axis == Axis.vertical
                                    ? MediaQuery.of(context).size.height
                                    : 5,
                              ),
                            ),
                          ).positioned(
                            left: root.axis == Axis.vertical
                                ? state.resizeOffset
                                : null,
                            top: root.axis == Axis.horizontal
                                ? state.resizeOffset
                                : null,
                          )
                        ],
                      );
                    },
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    }
  }
}

class PageStack extends StatefulWidget {
  const PageStack({
    super.key,
    required this.pageManager,
    required this.delegate,
  });

  final PageManager pageManager;

  final HomeStackDelegate delegate;

  @override
  State<PageStack> createState() => _PageStackState();
}

class _PageStackState extends State<PageStack>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: FocusTraversalGroup(
        child: widget.pageManager.stackWidget(
          onDeleted: (view, index) {
            widget.delegate.didDeleteStackWidget(view, index);
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
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

abstract mixin class NavigationItem {
  Widget get leftBarItem;
  Widget? get rightBarItem => null;
  Widget tabBarItem(String pluginId);

  NavigationCallback get action => (id) => throw UnimplementedError();
}

class PageNotifier extends ChangeNotifier {
  Plugin _plugin;

  Widget get titleWidget => _plugin.widgetBuilder.leftBarItem;

  Widget tabBarWidget(String pluginId) =>
      _plugin.widgetBuilder.tabBarItem(pluginId);

  PageNotifier({Plugin? plugin})
      : _plugin = plugin ?? makePlugin(pluginType: PluginType.blank);

  /// This is the only place where the plugin is set.
  /// No need compare the old plugin with the new plugin. Just set it.
  set plugin(Plugin newPlugin) {
    _plugin.dispose();

    /// Set the plugin view as the latest view.
    FolderEventSetLatestView(ViewIdPB(value: newPlugin.id)).send();

    _plugin = newPlugin;
    notifyListeners();
  }

  Plugin get plugin => _plugin;
}

// PageManager manages the view for one Tab
class PageManager {
  final PageNotifier _notifier = PageNotifier();

  PageNotifier get notifier => _notifier;

  PageManager();

  Widget title() {
    return _notifier.plugin.widgetBuilder.leftBarItem;
  }

  Plugin get plugin => _notifier.plugin;

  void setPlugin(Plugin newPlugin) {
    _notifier.plugin = newPlugin;
  }

  void setStackWithId(String id) {
    // Navigate to the page with id
  }

  Widget stackTopBar({required HomeLayout layout, required String paneId}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _notifier),
      ],
      child: Selector<PageNotifier, Widget>(
        selector: (context, notifier) => notifier.titleWidget,
        builder: (context, widget, child) {
          return MoveWindowDetector(
            child: HomeTopBar(layout: layout, paneId: paneId),
          );
        },
      ),
    );
  }

  Widget stackWidget({required Function(ViewPB, int?) onDeleted}) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _notifier)],
      child: Consumer(
        builder: (_, PageNotifier notifier, __) {
          return FadingIndexedStack(
            index: getIt<PluginSandbox>().indexOf(notifier.plugin.pluginType),
            children: getIt<PluginSandbox>().supportPluginTypes.map(
              (pluginType) {
                if (pluginType == notifier.plugin.pluginType) {
                  final builder = notifier.plugin.widgetBuilder;
                  final pluginWidget = builder.buildWidget(
                    context: PluginContext(onDeleted: onDeleted),
                    shrinkWrap: false,
                  );

                  return Padding(
                    padding: builder.contentPadding,
                    child: pluginWidget,
                  );
                }

                return const BlankPage();
              },
            ).toList(),
          );
        },
      ),
    );
  }
}

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.layout, required this.paneId});

  final HomeLayout layout;
  final String paneId;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.onSecondaryContainer,
      height: HomeSizes.topBarHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HomeInsets.topBarTitlePadding,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HSpace(layout.menuSpacing),
            const FlowyNavigation(),
            const HSpace(16),
            ChangeNotifierProvider.value(
              value: Provider.of<PageNotifier>(context, listen: false),
              child: Consumer(
                builder: (_, PageNotifier notifier, __) =>
                    notifier.plugin.widgetBuilder.rightBarItem ??
                    const SizedBox.shrink(),
              ),
            ),
            BlocBuilder<PanesCubit, PanesState>(
              builder: (context, state) {
                return state.count > 1
                    ? IconButton(
                        onPressed: () {
                          context.read<PanesCubit>().closePane(paneId);
                        },
                        icon: const Icon(Icons.close_sharp),
                      )
                    : const SizedBox.shrink();
              },
            )
          ],
        ),
      ).bottomBorder(color: Theme.of(context).dividerColor),
    );
  }
}
