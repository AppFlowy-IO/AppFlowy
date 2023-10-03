import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/blank/blank.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_cubit/panes_cubit.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/navigation.dart';
import 'package:appflowy/workspace/presentation/home/panes/flowy_pane_group.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/extension.dart';
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PanesCubit, PanesState>(
      builder: (context, state) {
        _printTree(state.root);
        return BlocBuilder<HomeSettingBloc, HomeSettingState>(
          builder: (context, homeState) {
            return FlowyPaneGroup(
              groupHeight: layout.homePageHeight,
              groupWidth: layout.homePageWidth,
              node: state.root,
              layout: layout,
              delegate: delegate,
            );
          },
        );
      },
    );
  }

  //TODO(squidrye): Remove before merge
  void _printTree(PaneNode node, [String prefix = '']) {
    print('$prefix${node.encoding}');
    for (var child in node.children) {
      _printTree(child, '$prefix └─ ');
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
    if (widget.pageManager.readOnly) {
      return Stack(
        children: [
          AbsorbPointer(
            child: Opacity(
              opacity: 0.5,
              child: _buildWidgetStack(context),
            ),
          ),
          Positioned(child: _buildReadOnlyBanner())
        ],
      );
    }
    return _buildWidgetStack(context);
  }

  Widget _buildWidgetStack(BuildContext context) {
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

  Widget _buildReadOnlyBanner() {
    final colorScheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 20),
      child: Container(
        width: double.infinity,
        color: colorScheme.primary,
        child: FittedBox(
          alignment: Alignment.center,
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              FlowyText.medium(
                LocaleKeys.readOnlyViewText.tr(),
                fontSize: 14,
              ),
            ],
          ),
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
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(
      milliseconds: 250,
    ),
  });

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
  bool _readOnly;
  String position;

  Widget get titleWidget => _plugin.widgetBuilder.leftBarItem;

  Widget tabBarWidget(String pluginId) =>
      _plugin.widgetBuilder.tabBarItem(pluginId);

  PageNotifier({Plugin? plugin, bool? readOnly, required String encoding})
      : _plugin = plugin ?? makePlugin(pluginType: PluginType.blank),
        _readOnly = readOnly ?? false,
        position = encoding;

  /// This is the only place where the plugin is set.
  /// No need compare the old plugin with the new plugin. Just set it.
  set plugin(Plugin newPlugin) {
    _plugin.dispose();

    /// Set the plugin view as the latest view.
    FolderEventSetLatestView(ViewIdPB(value: newPlugin.id)).send();

    _plugin = newPlugin;
    notifyListeners();
  }

  set readOnlyStatus(bool status) {
    _readOnly = status;
    notifyListeners();
  }

  Plugin get plugin => _plugin;

  bool get readOnly => _readOnly;
}

// PageManager manages the view for one Tab
class PageManager {
  final PageNotifier _notifier;

  PageNotifier get notifier => _notifier;

  PageManager(String encoding) : _notifier = PageNotifier(encoding: encoding);

  Widget title() {
    return _notifier.plugin.widgetBuilder.leftBarItem;
  }

  Plugin get plugin => _notifier.plugin;

  bool get readOnly => _notifier.readOnly;

  void setPlugin(Plugin newPlugin) {
    _notifier.plugin = newPlugin;
  }

  void setReadOnlyStatus(bool status) {
    _notifier.readOnlyStatus = status;
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
                if (state.count <= 1) {
                  return const SizedBox.shrink();
                }

                return IconButton(
                  onPressed: () =>
                      context.read<PanesCubit>().closePane(paneId: paneId),
                  icon: const Icon(Icons.close_sharp),
                );
              },
            )
          ],
        ),
      ).bottomBorder(color: Theme.of(context).dividerColor),
    );
  }
}
