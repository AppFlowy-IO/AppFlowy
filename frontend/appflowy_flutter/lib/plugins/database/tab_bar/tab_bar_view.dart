import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/shared/share/share_button.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/favorite_button.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/more_view_actions.dart';
import 'package:appflowy/workspace/presentation/widgets/tab_bar_item.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'desktop/tab_bar_header.dart';
import 'mobile/mobile_tab_bar_header.dart';

abstract class DatabaseTabBarItemBuilder {
  const DatabaseTabBarItemBuilder();

  /// Returns the content of the tab bar item. The content is shown when the tab
  /// bar item is selected. It can be any kind of database view.
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
    bool shrinkWrap,
    String? initialRowId,
  );

  /// Returns the setting bar of the tab bar item. The setting bar is shown on the
  /// top right conner when the tab bar item is selected.
  Widget settingBar(
    BuildContext context,
    DatabaseController controller,
  );

  Widget settingBarExtension(
    BuildContext context,
    DatabaseController controller,
  );

  /// Should be called in case a builder has resources it
  /// needs to dispose of.
  ///
  // If we add any logic in this method, add @mustCallSuper !
  void dispose() {}
}

class DatabaseTabBarView extends StatefulWidget {
  const DatabaseTabBarView({
    super.key,
    required this.view,
    required this.shrinkWrap,
    this.initialRowId,
  });

  final ViewPB view;
  final bool shrinkWrap;

  /// Used to open a Row on plugin load
  ///
  final String? initialRowId;

  @override
  State<DatabaseTabBarView> createState() => _DatabaseTabBarViewState();
}

class _DatabaseTabBarViewState extends State<DatabaseTabBarView> {
  final PageController _pageController = PageController();
  late String? _initialRowId = widget.initialRowId;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DatabaseTabBarBloc>(
          create: (context) => DatabaseTabBarBloc(view: widget.view)
            ..add(const DatabaseTabBarEvent.initial()),
        ),
        BlocProvider<ViewBloc>(
          create: (context) =>
              ViewBloc(view: widget.view)..add(const ViewEvent.initial()),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<DatabaseTabBarBloc, DatabaseTabBarState>(
            listenWhen: (p, c) => p.selectedIndex != c.selectedIndex,
            listener: (context, state) {
              _initialRowId = null;
              _pageController.jumpToPage(state.selectedIndex);
            },
          ),
        ],
        child: Column(
          children: [
            if (PlatformExtension.isMobile) const VSpace(12),
            BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
              builder: (context, state) {
                return ValueListenableBuilder<bool>(
                  valueListenable: state
                      .tabBarControllerByViewId[state.parentView.id]!
                      .controller
                      .isLoading,
                  builder: (_, value, ___) {
                    if (value) {
                      return const SizedBox.shrink();
                    }

                    return PlatformExtension.isDesktop
                        ? const TabBarHeader()
                        : const MobileTabBarHeader();
                  },
                );
              },
            ),
            BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
              builder: (context, state) =>
                  pageSettingBarExtensionFromState(state),
            ),
            Expanded(
              child: BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
                builder: (context, state) => PageView(
                  pageSnapping: false,
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,
                  children: pageContentFromState(state),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> pageContentFromState(DatabaseTabBarState state) {
    return state.tabBars.map((tabBar) {
      final controller =
          state.tabBarControllerByViewId[tabBar.viewId]!.controller;

      return tabBar.builder.content(
        context,
        tabBar.view,
        controller,
        widget.shrinkWrap,
        _initialRowId,
      );
    }).toList();
  }

  Widget pageSettingBarExtensionFromState(DatabaseTabBarState state) {
    if (state.tabBars.length < state.selectedIndex) {
      return const SizedBox.shrink();
    }
    final tabBar = state.tabBars[state.selectedIndex];
    final controller =
        state.tabBarControllerByViewId[tabBar.viewId]!.controller;
    return tabBar.builder.settingBarExtension(
      context,
      controller,
    );
  }
}

class DatabaseTabBarViewPlugin extends Plugin {
  DatabaseTabBarViewPlugin({
    required ViewPB view,
    required PluginType pluginType,
    this.initialRowId,
  })  : _pluginType = pluginType,
        notifier = ViewPluginNotifier(view: view);

  @override
  final ViewPluginNotifier notifier;

  final PluginType _pluginType;
  late final ViewInfoBloc _viewInfoBloc;

  /// Used to open a Row on plugin load
  ///
  final String? initialRowId;

  @override
  PluginWidgetBuilder get widgetBuilder => DatabasePluginWidgetBuilder(
        bloc: _viewInfoBloc,
        notifier: notifier,
        initialRowId: initialRowId,
      );

  @override
  PluginId get id => notifier.view.id;

  @override
  PluginType get pluginType => _pluginType;

  @override
  void init() {
    _viewInfoBloc = ViewInfoBloc(view: notifier.view)
      ..add(const ViewInfoEvent.started());
  }

  @override
  void dispose() {
    _viewInfoBloc.close();
    notifier.dispose();
  }
}

const kDatabasePluginWidgetBuilderHorizontalPadding = 'horizontal_padding';

class DatabasePluginWidgetBuilderSize {
  const DatabasePluginWidgetBuilderSize({
    required this.horizontalPadding,
  });

  final double horizontalPadding;
}

class DatabasePluginWidgetBuilder extends PluginWidgetBuilder {
  DatabasePluginWidgetBuilder({
    required this.bloc,
    required this.notifier,
    this.initialRowId,
  });

  final ViewInfoBloc bloc;
  final ViewPluginNotifier notifier;

  /// Used to open a Row on plugin load
  ///
  final String? initialRowId;

  @override
  Widget get leftBarItem =>
      ViewTitleBar(key: ValueKey(notifier.view.id), view: notifier.view);

  @override
  Widget tabBarItem(String pluginId) => ViewTabBarItem(view: notifier.view);

  @override
  Widget buildWidget({
    required PluginContext context,
    required bool shrinkWrap,
    Map<String, dynamic>? data,
  }) {
    notifier.isDeleted.addListener(() {
      final deletedView = notifier.isDeleted.value;
      if (deletedView != null && deletedView.hasIndex()) {
        context.onDeleted?.call(notifier.view, deletedView.index);
      }
    });

    final horizontalPadding =
        data?[kDatabasePluginWidgetBuilderHorizontalPadding] as double? ??
            GridSize.horizontalHeaderPadding + 40;

    return Provider(
      create: (context) => DatabasePluginWidgetBuilderSize(
        horizontalPadding: horizontalPadding,
      ),
      child: DatabaseTabBarView(
        key: ValueKey(notifier.view.id),
        view: notifier.view,
        shrinkWrap: shrinkWrap,
        initialRowId: initialRowId,
      ),
    );
  }

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  Widget? get rightBarItem {
    final view = notifier.view;
    return BlocProvider<ViewInfoBloc>.value(
      value: bloc,
      child: Row(
        children: [
          ShareButton(key: ValueKey(view.id), view: view),
          const HSpace(10),
          ViewFavoriteButton(view: view),
          const HSpace(4),
          MoreViewActions(view: view, isDocument: false),
        ],
      ),
    );
  }

  @override
  EdgeInsets get contentPadding => const EdgeInsets.only(top: 28);
}
