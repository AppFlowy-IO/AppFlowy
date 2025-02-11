import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:appflowy/core/frameless_window.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/blank/blank.dart';
import 'package:appflowy/shared/window_title_bar.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/util/theme_extension.dart';
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
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  final overlayController = OverlayPortalController();
  final layerLink = LayerLink();

  late final ValueNotifier<double> widthNotifier;

  late final AnimationController animationController;
  late Animation<double> widthAnimation;
  late final Animation<Offset> offsetAnimation;

  late bool hasSecondaryView;

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

    widget.pageManager.secondaryNotifier.addListener(onSecondaryViewChanged);
    onSecondaryViewChanged();

    overlayController.show();
  }

  @override
  void dispose() {
    widget.pageManager.showSecondaryPluginNotifier
        .removeListener(onShowSecondaryChanged);
    widget.pageManager.secondaryNotifier.removeListener(onSecondaryViewChanged);
    widthNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isLightMode = Theme.of(context).isLightMode;
    return OverlayPortal(
      controller: overlayController,
      overlayChildBuilder: (context) {
        return ValueListenableBuilder(
          valueListenable: widget.pageManager.showSecondaryPluginNotifier,
          builder: (context, isShowing, child) {
            return CompositedTransformFollower(
              link: layerLink,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0.0, 120.0),
              child: Align(
                alignment: AlignmentDirectional.topEnd,
                child: AnimatedSwitcher(
                  duration: 150.milliseconds,
                  transitionBuilder: (child, animation) {
                    return NonClippingSizeTransition(
                      sizeFactor: animation,
                      axis: Axis.horizontal,
                      axisAlignment: -1,
                      child: child,
                    );
                  },
                  child: isShowing || !hasSecondaryView
                      ? const SizedBox.shrink()
                      : GestureDetector(
                          onTap: () => widget.pageManager
                              .showSecondaryPluginNotifier.value = true,
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              borderRadius: getBorderRadius(),
                              color: Theme.of(context).colorScheme.surface,
                              boxShadow: [
                                BoxShadow(
                                  offset: const Offset(0, 4),
                                  blurRadius: 20,
                                  color: isLightMode
                                      ? const Color(0x1F1F2329)
                                      : Theme.of(context)
                                          .shadowColor
                                          .withValues(alpha: 0.08),
                                ),
                              ],
                            ),
                            child: FlowyHover(
                              style: HoverStyle(
                                borderRadius: getBorderRadius(),
                                border: getBorder(context),
                              ),
                              child: const Center(
                                child: FlowySvg(
                                  FlowySvgs.rename_s,
                                  size: Size.square(16.0),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            );
          },
        );
      },
      child: CompositedTransformTarget(
        link: layerLink,
        child: Container(
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
                                child: widget.pageManager
                                    .stackSecondaryWidget(value),
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
        ),
      ),
    );
  }

  BoxBorder getBorder(BuildContext context) {
    final isLightMode = Theme.of(context).isLightMode;
    final borderSide = BorderSide(
      color: isLightMode
          ? const Color(0x141F2329)
          : Theme.of(context).dividerColor,
    );

    return Border(
      left: borderSide,
      top: borderSide,
      bottom: borderSide,
    );
  }

  BorderRadius getBorderRadius() {
    return const BorderRadius.only(
      topLeft: Radius.circular(12.0),
      bottomLeft: Radius.circular(12.0),
    );
  }

  void onSecondaryViewChanged() {
    hasSecondaryView = widget.pageManager.secondaryNotifier.plugin.pluginType !=
        PluginType.blank;
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

  void setPlugin(
    Plugin newPlugin, {
    required bool setLatest,
    bool disposeExisting = true,
  }) {
    if (newPlugin.id != plugin.id && disposeExisting) {
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
    _notifier.setPlugin(newPlugin, setLatest: setLatest);
  }

  void setSecondaryPlugin(Plugin newPlugin) {
    newPlugin.init();
    _secondaryNotifier.setPlugin(newPlugin, setLatest: false);
  }

  void expandSecondaryPlugin() {
    _notifier.setPlugin(_secondaryNotifier.plugin, setLatest: true);
    _secondaryNotifier.setPlugin(
      BlankPagePlugin(),
      setLatest: false,
      disposeExisting: false,
    );
  }

  void showSecondaryPlugin() {
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
          if (notifier.plugin.pluginType == PluginType.blank) {
            return const BlankPage();
          }

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
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
              tooltipText: LocaleKeys.sideBar_closeSidebar.tr(),
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
              tooltipText: LocaleKeys.sideBar_expandSidebar.tr(),
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

/// A version of Flutter's built in SizeTransition widget that clips the child
/// more sparingly than the original.
class NonClippingSizeTransition extends AnimatedWidget {
  const NonClippingSizeTransition({
    super.key,
    this.axis = Axis.vertical,
    required Animation<double> sizeFactor,
    this.axisAlignment = 0.0,
    this.fixedCrossAxisSizeFactor,
    this.child,
  })  : assert(
          fixedCrossAxisSizeFactor == null || fixedCrossAxisSizeFactor >= 0.0,
        ),
        super(listenable: sizeFactor);

  /// [Axis.horizontal] if [sizeFactor] modifies the width, otherwise
  /// [Axis.vertical].
  final Axis axis;

  /// The animation that controls the (clipped) size of the child.
  ///
  /// The width or height (depending on the [axis] value) of this widget will be
  /// its intrinsic width or height multiplied by [sizeFactor]'s value at the
  /// current point in the animation.
  ///
  /// If the value of [sizeFactor] is less than one, the child will be clipped
  /// in the appropriate axis.
  Animation<double> get sizeFactor => listenable as Animation<double>;

  /// Describes how to align the child along the axis that [sizeFactor] is
  /// modifying.
  ///
  /// A value of -1.0 indicates the top when [axis] is [Axis.vertical], and the
  /// start when [axis] is [Axis.horizontal]. The start is on the left when the
  /// text direction in effect is [TextDirection.ltr] and on the right when it
  /// is [TextDirection.rtl].
  ///
  /// A value of 1.0 indicates the bottom or end, depending upon the [axis].
  ///
  /// A value of 0.0 (the default) indicates the center for either [axis] value.
  final double axisAlignment;

  /// The factor by which to multiply the cross axis size of the child.
  ///
  /// If the value of [fixedCrossAxisSizeFactor] is less than one, the child
  /// will be clipped along the appropriate axis.
  ///
  /// If `null` (the default), the cross axis size is as large as the parent.
  final double? fixedCrossAxisSizeFactor;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final AlignmentDirectional alignment;
    final Edge edge;
    if (axis == Axis.vertical) {
      alignment = AlignmentDirectional(-1.0, axisAlignment);
      edge = switch (axisAlignment) { -1.0 => Edge.bottom, _ => Edge.top };
    } else {
      alignment = AlignmentDirectional(axisAlignment, -1.0);
      edge = switch (axisAlignment) { -1.0 => Edge.right, _ => Edge.left };
    }
    return ClipRect(
      clipper: EdgeRectClipper(edge: edge, margin: 20),
      child: Align(
        alignment: alignment,
        heightFactor: axis == Axis.vertical
            ? max(sizeFactor.value, 0.0)
            : fixedCrossAxisSizeFactor,
        widthFactor: axis == Axis.horizontal
            ? max(sizeFactor.value, 0.0)
            : fixedCrossAxisSizeFactor,
        child: child,
      ),
    );
  }
}

class EdgeRectClipper extends CustomClipper<Rect> {
  const EdgeRectClipper({
    required this.edge,
    required this.margin,
  });

  final Edge edge;
  final double margin;

  @override
  Rect getClip(Size size) {
    return switch (edge) {
      Edge.left =>
        Rect.fromLTRB(0.0, -margin, size.width + margin, size.height + margin),
      Edge.right =>
        Rect.fromLTRB(-margin, -margin, size.width, size.height + margin),
      Edge.top =>
        Rect.fromLTRB(-margin, 0.0, size.width + margin, size.height + margin),
      Edge.bottom => Rect.fromLTRB(-margin, -margin, size.width, size.height),
    };
  }

  @override
  bool shouldReclip(covariant CustomClipper<Rect> oldClipper) => false;
}

enum Edge {
  left,
  top,
  right,
  bottom;

  bool get isHorizontal => switch (this) {
        left || right => true,
        _ => false,
      };

  bool get isVertical => !isHorizontal;
}
