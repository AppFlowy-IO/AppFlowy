import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/core/config/kv_keys.dart';
import 'package:appflowy/features/page_access_level/logic/page_access_level_bloc.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/document/presentation/compact_mode_event.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/database/database_view_block_component.dart';
import 'package:appflowy/plugins/shared/share/share_button.dart';
import 'package:appflowy/plugins/util.dart';
import 'package:appflowy/startup/plugin/plugin.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/application/view/view_ext.dart';
import 'package:appflowy/workspace/application/view_info/view_info_bloc.dart';
import 'package:appflowy/workspace/presentation/home/home_stack.dart';
import 'package:appflowy/workspace/presentation/widgets/favorite_button.dart';
import 'package:appflowy/workspace/presentation/widgets/more_view_actions/more_view_actions.dart';
import 'package:appflowy/workspace/presentation/widgets/tab_bar_item.dart';
import 'package:appflowy/workspace/presentation/widgets/view_title_bar.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:universal_platform/universal_platform.dart';

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
    required this.showActions,
    this.initialRowId,
    this.actionBuilder,
    this.node,
  });

  final ViewPB view;
  final bool shrinkWrap;
  final BlockComponentActionBuilder? actionBuilder;
  final bool showActions;
  final Node? node;

  /// Used to open a Row on plugin load
  ///
  final String? initialRowId;

  @override
  State<DatabaseTabBarView> createState() => _DatabaseTabBarViewState();
}

class _DatabaseTabBarViewState extends State<DatabaseTabBarView> {
  bool enableCompactMode = false;
  bool initialed = false;
  StreamSubscription<CompactModeEvent>? compactModeSubscription;

  String get compactModeId => widget.node?.id ?? widget.view.id;

  @override
  void initState() {
    super.initState();
    if (widget.node != null) {
      enableCompactMode =
          widget.node!.attributes[DatabaseBlockKeys.enableCompactMode] ?? false;
      setState(() {
        initialed = true;
      });
    } else {
      fetchLocalCompactMode(compactModeId).then((v) {
        if (mounted) {
          setState(() {
            enableCompactMode = v;
            initialed = true;
          });
        }
      });
      compactModeSubscription =
          compactModeEventBus.on<CompactModeEvent>().listen((event) {
        if (event.id != widget.view.id) return;
        updateLocalCompactMode(event.enable);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    compactModeSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    if (!initialed) return Center(child: CircularProgressIndicator());
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final editorState = context.read<EditorState?>();
        final maxDocWidth = editorState?.editorStyle.maxWidth ?? maxWidth;
        final paddingLeft = max(0, maxWidth - maxDocWidth) / 2;
        return MultiBlocProvider(
          providers: [
            BlocProvider<DatabaseTabBarBloc>(
              create: (_) => DatabaseTabBarBloc(
                view: widget.view,
                compactModeId: compactModeId,
                enableCompactMode: enableCompactMode,
              )..add(const DatabaseTabBarEvent.initial()),
            ),
            BlocProvider<ViewBloc>(
              create: (_) => ViewBloc(view: widget.view)
                ..add(
                  const ViewEvent.initial(),
                ),
            ),
          ],
          child: BlocBuilder<DatabaseTabBarBloc, DatabaseTabBarState>(
            builder: (innerContext, state) {
              final layout = state.tabBars[state.selectedIndex].layout;
              final isCalendar = layout == ViewLayoutPB.Calendar;
              final databseBuilderSize =
                  context.read<DatabasePluginWidgetBuilderSize>();
              final horizontalPadding = databseBuilderSize.horizontalPadding;
              final showActionWrapper = widget.showActions &&
                  widget.actionBuilder != null &&
                  widget.node != null;
              final Widget child = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (UniversalPlatform.isMobile) const VSpace(12),
                  ValueListenableBuilder<bool>(
                    valueListenable: state
                        .tabBarControllerByViewId[state.parentView.id]!
                        .controller
                        .isLoading,
                    builder: (_, value, ___) {
                      if (value) {
                        return const SizedBox.shrink();
                      }

                      Widget child = UniversalPlatform.isDesktop
                          ? const TabBarHeader()
                          : const MobileTabBarHeader();

                      if (innerContext.watch<ViewBloc>().state.view.isLocked) {
                        child = IgnorePointer(
                          child: child,
                        );
                      }

                      if (showActionWrapper) {
                        child = BlockComponentActionWrapper(
                          node: widget.node!,
                          actionBuilder: widget.actionBuilder!,
                          child: Padding(
                            padding: EdgeInsets.only(right: horizontalPadding),
                            child: child,
                          ),
                        );
                      }

                      if (UniversalPlatform.isDesktop) {
                        child = Container(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding + paddingLeft,
                            0,
                            horizontalPadding + (isCalendar ? paddingLeft : 0),
                            0,
                          ),
                          child: child,
                        );
                      }

                      return child;
                    },
                  ),
                  pageSettingBarExtensionFromState(
                    context,
                    state,
                    horizontalPadding,
                  ),
                  wrapContent(
                    layout: layout,
                    child: Padding(
                      padding: (widget.shrinkWrap || showActionWrapper)
                          ? EdgeInsets.only(
                              left: 42 - horizontalPadding,
                              right: isCalendar ? paddingLeft : 0,
                            )
                          : EdgeInsets.zero,
                      child: Provider(
                        create: (_) => DatabasePluginWidgetBuilderSize(
                          horizontalPadding: horizontalPadding,
                          paddingLeftWithMaxDocumentWidth: paddingLeft,
                          verticalPadding: databseBuilderSize.verticalPadding,
                        ),
                        child: pageContentFromState(context, state),
                      ),
                    ),
                  ),
                ],
              );

              return child;
            },
          ),
        );
      },
    );
  }

  Future<bool> fetchLocalCompactMode(String compactModeId) async {
    Set<String> compactModeIds = {};
    try {
      final localIds = await getIt<KeyValueStorage>().get(
        KVKeys.compactModeIds,
      );
      final List<dynamic> decodedList = jsonDecode(localIds ?? '');
      compactModeIds = Set.from(decodedList.map((item) => item as String));
    } catch (e) {
      Log.warn('fetch local compact mode from id :$compactModeId failed', e);
    }
    return compactModeIds.contains(compactModeId);
  }

  Future<void> updateLocalCompactMode(bool enableCompactMode) async {
    Set<String> compactModeIds = {};
    try {
      final localIds = await getIt<KeyValueStorage>().get(
        KVKeys.compactModeIds,
      );
      final List<dynamic> decodedList = jsonDecode(localIds ?? '');
      compactModeIds = Set.from(decodedList.map((item) => item as String));
    } catch (e) {
      Log.warn('get compact mode ids failed', e);
    }
    if (enableCompactMode) {
      compactModeIds.add(compactModeId);
    } else {
      compactModeIds.remove(compactModeId);
    }
    await getIt<KeyValueStorage>().set(
      KVKeys.compactModeIds,
      jsonEncode(compactModeIds.toList()),
    );
  }

  Widget wrapContent({required ViewLayoutPB layout, required Widget child}) {
    if (widget.shrinkWrap) {
      if (layout.shrinkWrappable) {
        return child;
      }

      return SizedBox(
        height: layout.pluginHeight,
        child: child,
      );
    }

    return Expanded(child: child);
  }

  Widget pageContentFromState(BuildContext context, DatabaseTabBarState state) {
    final tab = state.tabBars[state.selectedIndex];
    final controller = state.tabBarControllerByViewId[tab.viewId]!.controller;

    return tab.builder.content(
      context,
      tab.view,
      controller,
      widget.shrinkWrap,
      widget.initialRowId,
    );
  }

  Widget pageSettingBarExtensionFromState(
    BuildContext context,
    DatabaseTabBarState state,
    double horizontalPadding,
  ) {
    if (state.tabBars.length < state.selectedIndex) {
      return const SizedBox.shrink();
    }
    final tabBar = state.tabBars[state.selectedIndex];
    final controller =
        state.tabBarControllerByViewId[tabBar.viewId]!.controller;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
      ),
      child: tabBar.builder.settingBarExtension(
        context,
        controller,
      ),
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
  late final PageAccessLevelBloc _pageAccessLevelBloc;

  /// Used to open a Row on plugin load
  ///
  final String? initialRowId;

  @override
  PluginWidgetBuilder get widgetBuilder => DatabasePluginWidgetBuilder(
        bloc: _viewInfoBloc,
        pageAccessLevelBloc: _pageAccessLevelBloc,
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
    _pageAccessLevelBloc = PageAccessLevelBloc(view: notifier.view)
      ..add(const PageAccessLevelEvent.initial());
  }

  @override
  void dispose() {
    _viewInfoBloc.close();
    _pageAccessLevelBloc.close();
    notifier.dispose();
  }
}

const kDatabasePluginWidgetBuilderHorizontalPadding = 'horizontal_padding';
const kDatabasePluginWidgetBuilderShowActions = 'show_actions';
const kDatabasePluginWidgetBuilderActionBuilder = 'action_builder';
const kDatabasePluginWidgetBuilderNode = 'node';

class DatabasePluginWidgetBuilderSize {
  const DatabasePluginWidgetBuilderSize({
    required this.horizontalPadding,
    this.verticalPadding = 16.0,
    this.paddingLeftWithMaxDocumentWidth = 0.0,
  });

  final double horizontalPadding;
  final double verticalPadding;
  final double paddingLeftWithMaxDocumentWidth;

  double get paddingLeft => paddingLeftWithMaxDocumentWidth + horizontalPadding;
}

class DatabasePluginWidgetBuilder extends PluginWidgetBuilder {
  DatabasePluginWidgetBuilder({
    required this.bloc,
    required this.pageAccessLevelBloc,
    required this.notifier,
    this.initialRowId,
  });

  final ViewInfoBloc bloc;
  final PageAccessLevelBloc pageAccessLevelBloc;
  final ViewPluginNotifier notifier;

  /// Used to open a Row on plugin load
  ///
  final String? initialRowId;

  @override
  String? get viewName => notifier.view.nameOrDefault;

  @override
  Widget get leftBarItem {
    return BlocProvider.value(
      value: pageAccessLevelBloc,
      child: ViewTitleBar(key: ValueKey(notifier.view.id), view: notifier.view),
    );
  }

  @override
  Widget tabBarItem(String pluginId, [bool shortForm = false]) =>
      ViewTabBarItem(view: notifier.view, shortForm: shortForm);

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
    final BlockComponentActionBuilder? actionBuilder =
        data?[kDatabasePluginWidgetBuilderActionBuilder];
    final bool showActions =
        data?[kDatabasePluginWidgetBuilderShowActions] ?? false;
    final Node? node = data?[kDatabasePluginWidgetBuilderNode];

    return Provider(
      create: (context) => DatabasePluginWidgetBuilderSize(
        horizontalPadding: horizontalPadding,
      ),
      child: DatabaseTabBarView(
        key: ValueKey(notifier.view.id),
        view: notifier.view,
        shrinkWrap: shrinkWrap,
        initialRowId: initialRowId,
        actionBuilder: actionBuilder,
        showActions: showActions,
        node: node,
      ),
    );
  }

  @override
  List<NavigationItem> get navigationItems => [this];

  @override
  Widget? get rightBarItem {
    final view = notifier.view;
    return MultiBlocProvider(
      providers: [
        BlocProvider<ViewInfoBloc>.value(
          value: bloc,
        ),
        BlocProvider<PageAccessLevelBloc>.value(
          value: pageAccessLevelBloc,
        ),
      ],
      child: Row(
        children: [
          ShareButton(key: ValueKey(view.id), view: view),
          const HSpace(10),
          ViewFavoriteButton(view: view),
          const HSpace(4),
          MoreViewActions(view: view),
        ],
      ),
    );
  }

  @override
  EdgeInsets get contentPadding => const EdgeInsets.only(top: 28);
}
