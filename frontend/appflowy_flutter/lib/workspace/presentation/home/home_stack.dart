import 'dart:io';

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

import 'home_layout.dart';

typedef NavigationCallback = void Function(String id);

abstract class HomeStackDelegate {
  void didDeleteStackWidget(ViewPB view, int? index);
}

class HomeStack extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final pageController = PageController();

    return BlocProvider<TabsBloc>.value(
      value: getIt<TabsBloc>(),
      child: BlocBuilder<TabsBloc, TabsState>(
        builder: (context, state) {
          return Column(
            children: [
              if (Platform.isWindows)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WindowTitleBar(
                      leftChildren: [
                        _buildToggleMenuButton(context),
                      ],
                    ),
                  ],
                ),
              Padding(
                padding: EdgeInsets.only(left: layout.menuSpacing),
                child: TabsManager(pageController: pageController),
              ),
              state.currentPageManager.stackTopBar(layout: layout),
              Expanded(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: pageController,
                  children: state.pageManagers
                      .map(
                        (pm) => PageStack(
                          pageManager: pm,
                          delegate: delegate,
                          userProfile: userProfile,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
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
  PageNotifier({Plugin? plugin})
      : _plugin = plugin ?? makePlugin(pluginType: PluginType.blank);

  Plugin _plugin;

  Widget get titleWidget => _plugin.widgetBuilder.leftBarItem;

  Widget tabBarWidget(String pluginId) =>
      _plugin.widgetBuilder.tabBarItem(pluginId);

  /// This is the only place where the plugin is set.
  /// No need compare the old plugin with the new plugin. Just set it.
  void setPlugin(Plugin newPlugin, bool setLatest) {
    _plugin.dispose();
    newPlugin.init();

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

  PageNotifier get notifier => _notifier;

  Widget title() {
    return _notifier.plugin.widgetBuilder.leftBarItem;
  }

  Plugin get plugin => _notifier.plugin;

  void setPlugin(Plugin newPlugin, bool setLatest) {
    _notifier.setPlugin(newPlugin, setLatest);
  }

  void setStackWithId(String id) {
    // Navigate to the page with id
  }

  Widget stackTopBar({required HomeLayout layout}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _notifier),
      ],
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
                    context: PluginContext(
                      onDeleted: onDeleted,
                      userProfile: userProfile,
                    ),
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
        },
      ),
    );
  }

  void dispose() {
    _notifier.dispose();
  }
}

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.layout});

  final HomeLayout layout;

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
          ],
        ),
      ),
    );
  }
}
