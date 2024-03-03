import 'dart:async';

import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/blank/blank.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/panes/panes.dart';
import 'package:appflowy/workspace/application/panes/panes_bloc/panes_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/navigation.dart';
import 'package:appflowy/workspace/presentation/home/panes/flowy_pane_group.dart';
import 'package:appflowy/workspace/presentation/home/panes/panes_layout.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
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
  const HomeStack({
    super.key,
    required this.delegate,
    this.paneNode,
    required this.layout,
  });

  final HomeStackDelegate delegate;
  final HomeLayout layout;
  final PaneNode? paneNode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PanesBloc, PanesState>(
      buildWhen: (previous, current) =>
          previous.count != current.count ||
          previous.root != current.root ||
          previous.allowPaneDrag != current.allowPaneDrag ||
          previous.firstLeafNode != current.firstLeafNode,
      builder: (context, state) {
        return BlocBuilder<HomeSettingBloc, HomeSettingState>(
          builder: (context, homeState) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return FlowyPaneGroup(
                  node: state.root,
                  layout: layout,
                  delegate: delegate,
                  allowPaneDrag: state.allowPaneDrag,
                  paneLayout: PaneLayout.initial(
                    homeLayout: layout,
                    parentConstraints: constraints,
                    root: state.root,
                  ),
                );
              },
            );
          },
        );
      },
    );
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

class _PageStackState extends State<PageStack> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _buildWidgetStack(context);
  }

  Widget _buildWidgetStack(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: FocusTraversalGroup(
        descendantsAreFocusable: !widget.pageManager.readOnly,
        child: widget.pageManager.stackWidget(
          onDeleted: (view, index) {
            widget.delegate.didDeleteStackWidget(view, index);
          },
          context: context,
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class FadingIndexedStack extends StatefulWidget {
  const FadingIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(
      milliseconds: 250,
    ),
  });

  final int index;
  final List<Widget> children;
  final Duration duration;

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
  const NavigationItem();

  Widget get leftBarItem;
  Widget? get rightBarItem => null;
  Widget tabBarItem(String pluginId);

  NavigationCallback get action => (id) => throw UnimplementedError();
}

class PageNotifier extends ChangeNotifier {
  PageNotifier({Plugin? plugin, bool? readOnly})
      : _plugin = plugin ?? makePlugin(pluginType: PluginType.blank),
        _readOnly = readOnly ?? false;

  Plugin _plugin;
  bool _readOnly;

  Widget get titleWidget => _plugin.widgetBuilder.leftBarItem;

  Widget tabBarWidget(String pluginId) => _plugin.widgetBuilder.tabBarItem(pluginId);

  /// This is the only place where the plugin is set.
  /// No need compare the old plugin with the new plugin. Just set it.
  set plugin(Plugin newPlugin) {
    _plugin.dispose();
    newPlugin.init();

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
  PageManager();

  final PageNotifier _notifier = PageNotifier();

  PageNotifier get notifier => _notifier;

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
    _notifier._plugin.notifier?.readOnlyStatus = status;
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
            child: HomeTopBar(
              layout: layout,
              paneId: paneId,
              notifier: notifier,
            ),
          );
        },
      ),
    );
  }

  Widget stackWidget({
    required Function(ViewPB, int?) onDeleted,
    required BuildContext context,
  }) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _notifier)],
      child: Consumer(
        builder: (_, PageNotifier notifier, __) {
          return HomeBody(
            notifier: notifier,
            onDeleted: onDeleted,
          );
        },
      ),
    );
  }

  void dispose() {
    _notifier.dispose();
  }
}

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.layout,
    required this.paneId,
    required this.notifier,
  });

  final PageNotifier notifier;
  final HomeLayout layout;
  final String paneId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
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
                FlowyNavigation(currentPaneId: paneId),
                const HSpace(16),
                ChangeNotifierProvider.value(
                  value: Provider.of<PageNotifier>(context, listen: false),
                  child: Consumer(
                    builder: (_, PageNotifier notifier, __) =>
                        notifier.plugin.widgetBuilder.rightBarItem ?? const SizedBox.shrink(),
                  ),
                ),
                BlocBuilder<PanesBloc, PanesState>(
                  builder: (context, state) {
                    if (state.count <= 1) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.all(2),
                      child: FlowyIconButton(
                        iconColorOnHover: Theme.of(context).colorScheme.onSurface,
                        onPressed: () => context.read<PanesBloc>().add(ClosePane(paneId: paneId)),
                        icon: const FlowySvg(FlowySvgs.close_s),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (notifier.readOnly) _buildReadOnlyBanner(context),
      ],
    );
  }

  Widget _buildReadOnlyBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
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
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeBody extends StatefulWidget {
  final PageNotifier notifier;
  final Function(ViewPB, int?) onDeleted;

  const HomeBody({
    super.key,
    required this.notifier,
    required this.onDeleted,
  });

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late final absorbTapsNotifier = ValueNotifier<bool>(widget.notifier.readOnly);
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.notifier.readOnly) {
      return ValueListenableBuilder(
        valueListenable: absorbTapsNotifier,
        builder: (_, value, __) => GestureDetector(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerPanZoomUpdate: (event) {
              absorbTapsNotifier.value = false;
              _timer?.cancel();
            },
            onPointerPanZoomEnd: (event) {
              _timer?.cancel();
              _applyTimer();
            },
            onPointerPanZoomStart: (event) {
              absorbTapsNotifier.value = false;
              _timer?.cancel();
            },
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) {
                absorbTapsNotifier.value = false;
                _timer?.cancel();
                _applyTimer();
              }
            },
            child: IgnorePointer(
              ignoring: value,
              child: Opacity(
                opacity: 0.5,
                child: _buildWidgetStack(onDeleted: widget.onDeleted),
              ),
            ),
          ),
        ),
      );
    }
    return _buildWidgetStack(onDeleted: widget.onDeleted);
  }

  void _applyTimer() {
    _timer = Timer(const Duration(milliseconds: 600), () {
      absorbTapsNotifier.value = true;
      _timer?.cancel();
    });
  }

  Widget _buildWidgetStack({required Function(ViewPB, int?) onDeleted}) {
    return FadingIndexedStack(
      index: getIt<PluginSandbox>().indexOf(widget.notifier.plugin.pluginType),
      children: getIt<PluginSandbox>().supportPluginTypes.map(
        (pluginType) {
          if (pluginType == widget.notifier.plugin.pluginType) {
            final builder = widget.notifier.plugin.widgetBuilder;
            final pluginWidget = builder.buildWidget(
              context: PluginContext(onDeleted: onDeleted),
              shrinkWrap: false,
            );

            // TODO(Xazin): Board should fill up full width
            return Padding(
              padding: builder.contentPadding,
              child: pluginWidget,
            );
          }

          return const BlankPage();
        },
      ).toList(),
    );
  }
}
