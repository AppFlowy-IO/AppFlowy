import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/blank/blank.dart';
import 'package:appflowy/shared/window_title_bar.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/home/home_setting_bloc.dart';
import 'package:appflowy/workspace/application/tabs/tabs_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_sizes.dart';
import 'package:appflowy/workspace/presentation/home/navigation.dart';
import 'package:appflowy/workspace/presentation/home/tabs/tabs_manager.dart';
import 'package:appflowy/workspace/presentation/home/toast.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:time/time.dart';
import 'package:universal_platform/universal_platform.dart';

import 'home_layout.dart';

typedef NavigationCallback = void Function(String id);

abstract class HomeStackDelegate {
  void didDeleteStackWidget(ViewPB view, int? index);
}

class HomeStack extends StatefulWidget {
  const HomeStack({
    super.key,
    required this.delegate,
    required this.layout,
    required this.userProfile,
  });

  final HomeStackDelegate delegate;
  final HomeLayout layout;
  final UserProfilePB userProfile;

  @override
  State<HomeStack> createState() => _HomeStackState();
}

class _HomeStackState extends State<HomeStack> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TabsBloc>.value(
      value: getIt<TabsBloc>(),
      child: BlocBuilder<TabsBloc, TabsState>(
        builder: (context, state) => Column(
          children: [
            if (UniversalPlatform.isWindows)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WindowTitleBar(
                    leftChildren: [_buildToggleMenuButton(context)],
                  ),
                ],
              ),
            Padding(
              padding: EdgeInsets.only(left: widget.layout.menuSpacing),
              child: TabsManager(
                onIndexChanged: (index) {
                  if (selectedIndex != index) {
                    // Unfocus editor to hide selection toolbar
                    FocusScope.of(context).unfocus();

                    context.read<TabsBloc>().add(TabsEvent.selectTab(index));
                    setState(() => selectedIndex = index);
                  }
                },
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: selectedIndex,
                children: state.pageManagers
                    .map(
                      (pm) => LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    pm.stackTopBar(layout: widget.layout),
                                    Expanded(
                                      child: PageStack(
                                        pageManager: pm,
                                        delegate: widget.delegate,
                                        userProfile: widget.userProfile,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SecondaryView(
                                pageManager: pm,
                                adaptedPercentageWidth:
                                    constraints.maxWidth * 3 / 7,
                              ),
                            ],
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleMenuButton(BuildContext context) {
    if (!context.read<HomeSettingBloc>().state.isMenuCollapsed) {
      return const SizedBox.shrink();
    }

    final textSpan = TextSpan(
      children: [
        TextSpan(
          text: '${LocaleKeys.sideBar_openSidebar.tr()}\n',
          style: context.tooltipTextStyle(),
        ),
        TextSpan(
          text: Platform.isMacOS ? '⌘+.' : 'Ctrl+\\',
          style: context
              .tooltipTextStyle()
              ?.copyWith(color: Theme.of(context).hintColor),
        ),
      ],
    );

    return FlowyTooltip(
      richMessage: textSpan,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => context
            .read<HomeSettingBloc>()
            .add(const HomeSettingEvent.collapseMenu()),
        child: FlowyHover(
          child: Container(
            width: 24,
            padding: const EdgeInsets.all(4),
            child: const RotatedBox(
              quarterTurns: 2,
              child: FlowySvg(FlowySvgs.hide_menu_s),
            ),
          ),
        ),
      ),
    );
  }
}

class PageStack extends StatefulWidget {
  const PageStack({
    super.key,
    required this.pageManager,
    required this.delegate,
    required this.userProfile,
  });

  final PageManager pageManager;
  final HomeStackDelegate delegate;
  final UserProfilePB userProfile;

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
          userProfile: widget.userProfile,
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

class SecondaryView extends StatefulWidget {
  const SecondaryView({
    super.key,
    required this.pageManager,
    required this.adaptedPercentageWidth,
  });

  final PageManager pageManager;
  final double adaptedPercentageWidth;

  @override
  State<SecondaryView> createState() => _SecondaryViewState();
}

class _SecondaryViewState extends State<SecondaryView>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final ValueNotifier<double> widthNotifier;

  late final AnimationController animationController;
  late Animation<double> widthAnimation;
  late final Animation<Offset> offsetAnimation;

  CurvedAnimation get curveAnimation => CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOut,
      );

  @override
  void initState() {
    super.initState();
    widget.pageManager.showSecondaryPluginNotifier
        .addListener(onShowSecondaryChanged);
    final width = widget.pageManager.showSecondaryPluginNotifier.value
        ? max(450.0, widget.adaptedPercentageWidth)
        : 0.0;
    widthNotifier = ValueNotifier<double>(width)
      ..addListener(updateWidthAnimation);

    animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    widthAnimation = Tween<double>(
      begin: 0.0,
      end: width,
    ).animate(curveAnimation);
    offsetAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(curveAnimation);
  }

  @override
  void dispose() {
    widget.pageManager.showSecondaryPluginNotifier
        .removeListener(onShowSecondaryChanged);
    widthNotifier.dispose();
    super.dispose();
  }

  void onShowSecondaryChanged() async {
    if (widget.pageManager.showSecondaryPluginNotifier.value) {
      widthNotifier.value = max(450.0, widget.adaptedPercentageWidth);
      updateWidthAnimation();
      await animationController.forward();
    } else {
      updateWidthAnimation();
      await animationController.reverse();
      setState(() => widthNotifier.value = 0.0);
    }
  }

  void updateWidthAnimation() {
    widthAnimation = Tween<double>(
      begin: 0.0,
      end: widthNotifier.value,
    ).animate(curveAnimation);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: FocusTraversalGroup(
        child: ValueListenableBuilder(
          valueListenable: widthNotifier,
          builder: (context, value, child) {
            return AnimatedBuilder(
              animation: Listenable.merge([
                widthAnimation,
                offsetAnimation,
              ]),
              builder: (context, child) {
                return Container(
                  width: widthAnimation.value,
                  alignment: Alignment(
                    offsetAnimation.value.dx,
                    offsetAnimation.value.dy,
                  ),
                  child: OverflowBox(
                    alignment: AlignmentDirectional.centerStart,
                    maxWidth: value,
                    child: SecondaryViewResizer(
                      pageManager: widget.pageManager,
                      notifier: widthNotifier,
                      child: Column(
                        children: [
                          widget.pageManager.stackSecondaryTopBar(value),
                          Expanded(
                            child:
                                widget.pageManager.stackSecondaryWidget(value),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class SecondaryViewResizer extends StatefulWidget {
  const SecondaryViewResizer({
    super.key,
    required this.pageManager,
    required this.notifier,
    required this.child,
  });

  final PageManager pageManager;
  final ValueNotifier<double> notifier;
  final Widget child;

  @override
  State<SecondaryViewResizer> createState() => _SecondaryViewResizerState();
}

class _SecondaryViewResizerState extends State<SecondaryViewResizer> {
  final overlayController = OverlayPortalController();
  final layerLink = LayerLink();

  bool isHover = false;
  bool isDragging = false;
  Timer? showHoverTimer;

  @override
  void initState() {
    super.initState();
    overlayController.show();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: overlayController,
      overlayChildBuilder: (context) {
        return CompositedTransformFollower(
          showWhenUnlinked: false,
          link: layerLink,
          targetAnchor: Alignment.center,
          followerAnchor: Alignment.center,
          child: Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.resizeLeftRight,
              onEnter: (_) {
                showHoverTimer = Timer(const Duration(milliseconds: 500), () {
                  setState(() => isHover = true);
                });
              },
              onExit: (_) {
                showHoverTimer?.cancel();
                setState(() => isHover = false);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (_) => setState(() => isDragging = true),
                onHorizontalDragUpdate: (details) {
                  final newWidth = MediaQuery.sizeOf(context).width -
                      details.globalPosition.dx;
                  if (newWidth >= 450.0) {
                    widget.notifier.value = newWidth;
                  }
                },
                onHorizontalDragEnd: (_) => setState(() => isDragging = false),
                child: TweenAnimationBuilder(
                  tween: ColorTween(
                    end: isHover || isDragging
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                  ),
                  duration: const Duration(milliseconds: 100),
                  builder: (context, color, child) {
                    return SizedBox(
                      width: 11,
                      child: Center(
                        child: Container(
                          color: color,
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CompositedTransformTarget(
            link: layerLink,
            child: Container(
              width: 1,
              color: Theme.of(context).dividerColor,
            ),
          ),
          Flexible(child: widget.child),
        ],
      ),
    );
  }
}

class FadingIndexedStack extends StatefulWidget {
  const FadingIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = const Duration(milliseconds: 250),
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
    _targetOpacity = 0;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => setState(() => _targetOpacity = 1),
    );
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: _targetOpacity > 0 ? widget.duration : 0.milliseconds,
      tween: Tween(begin: 0, end: _targetOpacity),
      builder: (_, value, child) => Opacity(opacity: value, child: child),
      child: IndexedStack(index: widget.index, children: widget.children),
    );
  }
}

abstract mixin class NavigationItem {
  String? get viewName;
  Widget get leftBarItem;
  Widget? get rightBarItem => null;
  Widget tabBarItem(String pluginId, [bool shortForm = false]);

  NavigationCallback get action => (id) => throw UnimplementedError();
}

class PageNotifier extends ChangeNotifier {
  PageNotifier({Plugin? plugin})
      : _plugin = plugin ?? makePlugin(pluginType: PluginType.blank);

  Plugin _plugin;

  Widget get titleWidget => _plugin.widgetBuilder.leftBarItem;

  Widget tabBarWidget(
    String pluginId, [
    bool shortForm = false,
  ]) =>
      _plugin.widgetBuilder.tabBarItem(pluginId, shortForm);

  /// This is the only place where the plugin is set.
  /// No need compare the old plugin with the new plugin. Just set it.
  void setPlugin(Plugin newPlugin, bool setLatest) {
    if (newPlugin.id != plugin.id) {
      _plugin.dispose();
    }

    // Set the plugin view as the latest view.
    if (setLatest) {
      FolderEventSetLatestView(ViewIdPB(value: newPlugin.id)).send();
    }

    _plugin = newPlugin;
    notifyListeners();
  }

  Plugin get plugin => _plugin;
}

// PageManager manages the view for one Tab
class PageManager {
  PageManager();

  final PageNotifier _notifier = PageNotifier();
  final PageNotifier _secondaryNotifier = PageNotifier();

  PageNotifier get notifier => _notifier;
  PageNotifier get secondaryNotifier => _secondaryNotifier;

  bool isPinned = false;

  final showSecondaryPluginNotifier = ValueNotifier(false);

  Plugin get plugin => _notifier.plugin;

  void setPlugin(Plugin newPlugin, bool setLatest, [bool init = true]) {
    if (init) {
      newPlugin.init();
    }
    _notifier.setPlugin(newPlugin, setLatest);
  }

  void setSecondaryPlugin(Plugin newPlugin) {
    newPlugin.init();
    _secondaryNotifier.setPlugin(newPlugin, false);
    showSecondaryPluginNotifier.value = true;
  }

  void hideSecondaryPlugin() {
    showSecondaryPluginNotifier.value = false;
  }

  Widget stackTopBar({required HomeLayout layout}) {
    return ChangeNotifierProvider.value(
      value: _notifier,
      child: Selector<PageNotifier, Widget>(
        selector: (context, notifier) => notifier.titleWidget,
        builder: (_, __, child) => MoveWindowDetector(
          child: HomeTopBar(layout: layout),
        ),
      ),
    );
  }

  Widget stackWidget({
    required UserProfilePB userProfile,
    required Function(ViewPB, int?) onDeleted,
  }) {
    return ChangeNotifierProvider.value(
      value: _notifier,
      child: Consumer<PageNotifier>(
        builder: (_, notifier, __) {
          return FadingIndexedStack(
            index: getIt<PluginSandbox>().indexOf(notifier.plugin.pluginType),
            children: getIt<PluginSandbox>().supportPluginTypes.map(
              (pluginType) {
                if (pluginType == notifier.plugin.pluginType) {
                  final builder = notifier.plugin.widgetBuilder;
                  final pluginWidget = builder.buildWidget(
                    context: PluginContext(
                      onDeleted: onDeleted,
                      userProfile: userProfile,
                    ),
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

  Widget stackSecondaryWidget(double width) {
    return ValueListenableBuilder(
      valueListenable: showSecondaryPluginNotifier,
      builder: (context, value, child) {
        if (width == 0.0) {
          return const SizedBox.shrink();
        }

        return child!;
      },
      child: ChangeNotifierProvider.value(
        value: _secondaryNotifier,
        child: Selector<PageNotifier, PluginWidgetBuilder>(
          selector: (context, notifier) => notifier.plugin.widgetBuilder,
          builder: (_, widgetBuilder, __) {
            return widgetBuilder.buildWidget(
              context: PluginContext(),
              shrinkWrap: false,
            );
          },
        ),
      ),
    );
  }

  Widget stackSecondaryTopBar(double width) {
    return ValueListenableBuilder(
      valueListenable: showSecondaryPluginNotifier,
      builder: (context, value, child) {
        if (width == 0.0) {
          return const SizedBox.shrink();
        }

        return child!;
      },
      child: ChangeNotifierProvider.value(
        value: _secondaryNotifier,
        child: Selector<PageNotifier, PluginWidgetBuilder>(
          selector: (context, notifier) => notifier.plugin.widgetBuilder,
          builder: (_, widgetBuilder, __) {
            return const MoveWindowDetector(
              child: HomeSecondaryTopBar(),
            );
          },
        ),
      ),
    );
  }

  void dispose() {
    _notifier.dispose();
    _secondaryNotifier.dispose();
    showSecondaryPluginNotifier.dispose();
  }
}

class HomeTopBar extends StatefulWidget {
  const HomeTopBar({super.key, required this.layout});

  final HomeLayout layout;

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      height: HomeSizes.topBarHeight + HomeInsets.topBarTitleVerticalPadding,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HomeInsets.topBarTitleHorizontalPadding,
          vertical: HomeInsets.topBarTitleVerticalPadding,
        ),
        child: Row(
          children: [
            HSpace(widget.layout.menuSpacing),
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
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class HomeSecondaryTopBar extends StatelessWidget {
  const HomeSecondaryTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      height: HomeSizes.topBarHeight + HomeInsets.topBarTitleVerticalPadding,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HomeInsets.topBarTitleHorizontalPadding,
          vertical: HomeInsets.topBarTitleVerticalPadding,
        ),
        child: Row(
          children: [
            FlowyIconButton(
              width: 24,
              radius: const BorderRadius.all(Radius.circular(8.0)),
              icon: const FlowySvg(
                FlowySvgs.show_menu_s,
                size: Size.square(16),
              ),
              onPressed: () {
                getIt<TabsBloc>().add(const TabsEvent.closeSecondaryPlugin());
              },
            ),
            const HSpace(8.0),
            FlowyIconButton(
              width: 24,
              radius: const BorderRadius.all(Radius.circular(8.0)),
              icon: const FlowySvg(
                FlowySvgs.full_view_s,
                size: Size.square(16),
              ),
              onPressed: () {
                getIt<TabsBloc>().add(const TabsEvent.expandSecondaryPlugin());
              },
            ),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: ChangeNotifierProvider.value(
                  value: Provider.of<PageNotifier>(context, listen: false),
                  child: Consumer(
                    builder: (_, PageNotifier notifier, __) =>
                        notifier.plugin.widgetBuilder.rightBarItem ??
                        const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
