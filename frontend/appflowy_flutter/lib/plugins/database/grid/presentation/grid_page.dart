import 'dart:async';

import 'package:appflowy/plugins/database/grid/presentation/widgets/toolbar/grid_setting_bar.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/setting_menu.dart';
import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/application/tab_bar_bloc.dart';
import 'package:appflowy/plugins/database/domain/sort_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/calculations_row.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:provider/provider.dart';

import '../../application/database_controller.dart';
import '../../application/row/row_controller.dart';
import '../../tab_bar/tab_bar_view.dart';
import '../../widgets/row/row_detail.dart';
import '../application/grid_bloc.dart';

import 'grid_scroll.dart';
import 'layout/layout.dart';
import 'layout/sizes.dart';
import 'widgets/footer/grid_footer.dart';
import 'widgets/header/grid_header.dart';
import 'widgets/row/row.dart';
import 'widgets/shortcuts.dart';

class ToggleExtensionNotifier extends ChangeNotifier {
  bool _isToggled = false;

  bool get isToggled => _isToggled;

  void toggle() {
    _isToggled = !_isToggled;
    notifyListeners();
  }
}

class DesktopGridTabBarBuilderImpl extends DatabaseTabBarItemBuilder {
  final _toggleExtension = ToggleExtensionNotifier();

  @override
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
    bool shrinkWrap,
    String? initialRowId,
  ) {
    return GridPage(
      key: _makeValueKey(controller),
      view: view,
      databaseController: controller,
      initialRowId: initialRowId,
      shrinkWrap: shrinkWrap,
    );
  }

  @override
  Widget settingBar(BuildContext context, DatabaseController controller) {
    return GridSettingBar(
      key: _makeValueKey(controller),
      controller: controller,
      toggleExtension: _toggleExtension,
    );
  }

  @override
  Widget settingBarExtension(
    BuildContext context,
    DatabaseController controller,
  ) {
    return DatabaseViewSettingExtension(
      key: _makeValueKey(controller),
      viewId: controller.viewId,
      databaseController: controller,
      toggleExtension: _toggleExtension,
    );
  }

  @override
  void dispose() {
    _toggleExtension.dispose();
    super.dispose();
  }

  ValueKey _makeValueKey(DatabaseController controller) {
    return ValueKey(controller.viewId);
  }
}

class GridPage extends StatefulWidget {
  const GridPage({
    super.key,
    required this.view,
    required this.databaseController,
    this.onDeleted,
    this.initialRowId,
    this.shrinkWrap = false,
  });

  final ViewPB view;
  final DatabaseController databaseController;
  final VoidCallback? onDeleted;
  final String? initialRowId;
  final bool shrinkWrap;

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  bool _didOpenInitialRow = false;

  late final GridBloc gridBloc = GridBloc(
    view: widget.view,
    databaseController: widget.databaseController,
    shrinkWrapped: widget.shrinkWrap,
  )..add(const GridEvent.initial());

  @override
  void dispose() {
    gridBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GridBloc>(
      create: (_) => gridBloc,
      child: BlocListener<ActionNavigationBloc, ActionNavigationState>(
        listener: (context, state) {
          final action = state.action;
          if (action?.type == ActionType.openRow &&
              action?.objectId == widget.view.id) {
            final rowId = action!.arguments?[ActionArgumentKeys.rowId];
            if (rowId != null) {
              // If Reminder in existing database is pressed
              // then open the row
              _openRow(context, rowId);
            }
          }
        },
        child: BlocConsumer<GridBloc, GridState>(
          listener: listener,
          builder: (context, state) => state.loadingState.map(
            idle: (_) => const SizedBox.shrink(),
            loading: (_) => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            finish: (result) => result.successOrFail.fold(
              (_) => GridShortcuts(
                child: GridPageContent(
                  key: ValueKey(widget.view.id),
                  view: widget.view,
                  shrinkWrap: widget.shrinkWrap,
                ),
              ),
              (err) => Center(child: AppFlowyErrorPage(error: err)),
            ),
          ),
        ),
      ),
    );
  }

  void _openRow(BuildContext context, String rowId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gridBloc = context.read<GridBloc>();
      final rowCache = gridBloc.rowCache;
      final rowMeta = rowCache.getRow(rowId)?.rowMeta;
      if (rowMeta == null) {
        return;
      }

      final rowController = RowController(
        viewId: widget.view.id,
        rowMeta: rowMeta,
        rowCache: rowCache,
      );

      FlowyOverlay.show(
        context: context,
        builder: (_) => BlocProvider.value(
          value: context.read<ViewBloc>(),
          child: RowDetailPage(
            databaseController: context.read<GridBloc>().databaseController,
            rowController: rowController,
            userProfile: context.read<GridBloc>().userProfile,
          ),
        ),
      );
    });
  }

  void listener(BuildContext context, GridState state) {
    state.loadingState.whenOrNull(
      // If initial row id is defined, open row details overlay
      finish: (_) async {
        if (widget.initialRowId != null && !_didOpenInitialRow) {
          _didOpenInitialRow = true;

          _openRow(context, widget.initialRowId!);
          return;
        }

        final bloc = context.read<DatabaseTabBarBloc>();
        final isCurrentView =
            bloc.state.tabBars[bloc.state.selectedIndex].viewId ==
                widget.view.id;

        if (state.openRowDetail && state.createdRow != null && isCurrentView) {
          final rowController = RowController(
            viewId: widget.view.id,
            rowMeta: state.createdRow!,
            rowCache: context.read<GridBloc>().rowCache,
          );
          unawaited(
            FlowyOverlay.show(
              context: context,
              builder: (_) => BlocProvider.value(
                value: context.read<ViewBloc>(),
                child: RowDetailPage(
                  databaseController:
                      context.read<GridBloc>().databaseController,
                  rowController: rowController,
                  userProfile: context.read<GridBloc>().userProfile,
                ),
              ),
            ),
          );
          context.read<GridBloc>().add(const GridEvent.resetCreatedRow());
        }
      },
    );
  }
}

class GridPageContent extends StatefulWidget {
  const GridPageContent({
    super.key,
    required this.view,
    this.shrinkWrap = false,
  });

  final ViewPB view;
  final bool shrinkWrap;

  @override
  State<GridPageContent> createState() => _GridPageContentState();
}

class _GridPageContentState extends State<GridPageContent> {
  final _scrollController = GridScrollController(
    scrollGroupController: LinkedScrollControllerGroup(),
  );
  late final ScrollController headerScrollController;

  @override
  void initState() {
    super.initState();
    headerScrollController = _scrollController.linkHorizontalController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _GridHeader(headerScrollController: headerScrollController),
        _GridRows(
          viewId: widget.view.id,
          scrollController: _scrollController,
          shrinkWrap: widget.shrinkWrap,
        ),
      ],
    );
  }
}

class _GridHeader extends StatelessWidget {
  const _GridHeader({required this.headerScrollController});

  final ScrollController headerScrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridBloc, GridState>(
      builder: (_, state) => GridHeaderSliverAdaptor(
        viewId: state.viewId,
        anchorScrollController: headerScrollController,
      ),
    );
  }
}

class _GridRows extends StatefulWidget {
  const _GridRows({
    required this.viewId,
    required this.scrollController,
    this.shrinkWrap = false,
  });

  final String viewId;
  final GridScrollController scrollController;

  /// When [shrinkWrap] is active, the Grid will show items according to
  /// GridState.visibleRows and will not have a vertical scroll area.
  ///
  final bool shrinkWrap;

  @override
  State<_GridRows> createState() => _GridRowsState();
}

class _GridRowsState extends State<_GridRows> {
  bool showFloatingCalculations = false;
  bool isAtBottom = false;

  @override
  void initState() {
    super.initState();
    if (!widget.shrinkWrap) {
      _evaluateFloatingCalculations();
      widget.scrollController.verticalController.addListener(_onScrollChanged);
    }
  }

  void _onScrollChanged() {
    final controller = widget.scrollController.verticalController;
    final isAtBottom = controller.position.atEdge && controller.offset > 0 ||
        controller.offset >= controller.position.maxScrollExtent - 1;
    if (isAtBottom != this.isAtBottom) {
      setState(() => this.isAtBottom = isAtBottom);
    }
  }

  @override
  void dispose() {
    if (!widget.shrinkWrap) {
      widget.scrollController.verticalController
          .removeListener(_onScrollChanged);
    }
    super.dispose();
  }

  void _evaluateFloatingCalculations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !widget.shrinkWrap) {
        setState(() {
          final verticalController = widget.scrollController.verticalController;
          // maxScrollExtent is 0.0 if scrolling is not possible
          showFloatingCalculations =
              verticalController.position.maxScrollExtent > 0;

          isAtBottom = verticalController.position.atEdge &&
              verticalController.offset > 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.shrinkWrap) {
      child = Scrollbar(
        controller: widget.scrollController.horizontalController,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: widget.scrollController.horizontalController,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: GridLayout.headerWidth(
                context
                    .read<DatabasePluginWidgetBuilderSize>()
                    .horizontalPadding,
                context.read<GridBloc>().state.fields,
              ),
            ),
            child: _renderList(context),
          ),
        ),
      );
    } else {
      child = _WrapScrollView(
        scrollController: widget.scrollController,
        contentWidth: GridLayout.headerWidth(
          context.read<DatabasePluginWidgetBuilderSize>().horizontalPadding,
          context.read<GridBloc>().state.fields,
        ),
        child: BlocListener<GridBloc, GridState>(
          listenWhen: (previous, current) =>
              previous.rowCount != current.rowCount,
          listener: (context, state) => _evaluateFloatingCalculations(),
          child: ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: _renderList(context),
          ),
        ),
      );
    }

    if (widget.shrinkWrap) {
      return child;
    }

    return Flexible(child: child);
  }

  Widget _renderList(BuildContext context) {
    final state = context.read<GridBloc>().state;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.shrinkWrap
            ? _reorderableListView(state)
            : Expanded(child: _reorderableListView(state)),
        if (showFloatingCalculations && !widget.shrinkWrap) ...[
          _PositionedCalculationsRow(
            viewId: widget.viewId,
            isAtBottom: isAtBottom,
          ),
        ],
      ],
    );
  }

  Widget _reorderableListView(GridState state) {
    final List<Widget> footer = [
      const GridRowBottomBar(),
      if (widget.shrinkWrap && state.visibleRows < state.rowInfos.length)
        const GridRowLoadMoreButton(),
      if (!showFloatingCalculations) GridCalculationsRow(viewId: widget.viewId),
    ];

    // If we are using shrinkWrap, we need to show at most
    // state.visibleRows + 1 items. The visibleRows can be larger
    // than the actual rowInfos length.
    final itemCount = widget.shrinkWrap
        ? (state.visibleRows + 1).clamp(0, state.rowInfos.length + 1)
        : state.rowInfos.length + 1;

    return ReorderableListView.builder(
      cacheExtent: 500,
      scrollController: widget.scrollController.verticalController,
      physics: const ClampingScrollPhysics(),
      buildDefaultDragHandles: false,
      shrinkWrap: widget.shrinkWrap,
      proxyDecorator: (child, _, __) => Provider.value(
        value: context.read<DatabasePluginWidgetBuilderSize>(),
        child: Material(
          color: Colors.white.withOpacity(.1),
          child: Opacity(opacity: .5, child: child),
        ),
      ),
      onReorder: (fromIndex, newIndex) {
        final toIndex = newIndex > fromIndex ? newIndex - 1 : newIndex;

        if (state.sorts.isNotEmpty) {
          showCancelAndDeleteDialog(
            context: context,
            title: LocaleKeys.grid_sort_sortsActive.tr(
              namedArgs: {
                'intention': LocaleKeys.grid_row_reorderRowDescription.tr(),
              },
            ),
            description: LocaleKeys.grid_sort_removeSorting.tr(),
            confirmLabel: LocaleKeys.button_remove.tr(),
            closeOnAction: true,
            onDelete: () {
              SortBackendService(viewId: widget.viewId).deleteAllSorts();
              moveRow(fromIndex, toIndex);
            },
          );
        } else {
          moveRow(fromIndex, toIndex);
        }
      },
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == itemCount - 1) {
          return Column(
            key: const Key('grid_footer'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: footer,
          );
        }

        return _renderRow(
          context,
          state.rowInfos[index].rowId,
          index: index,
        );
      },
    );
  }

  Widget _renderRow(
    BuildContext context,
    RowId rowId, {
    required int index,
    Animation<double>? animation,
  }) {
    final databaseController = context.read<GridBloc>().databaseController;
    final DatabaseController(:viewId, :rowCache) = databaseController;
    final rowMeta = rowCache.getRow(rowId)?.rowMeta;

    /// Return placeholder widget if the rowMeta is null.
    if (rowMeta == null) {
      Log.warn('RowMeta is null for rowId: $rowId');
      return const SizedBox.shrink();
    }

    final child = GridRow(
      key: ValueKey("grid_row_$rowId"),
      shrinkWrap: widget.shrinkWrap,
      fieldController: databaseController.fieldController,
      rowId: rowId,
      viewId: viewId,
      index: index,
      rowController: RowController(
        viewId: viewId,
        rowMeta: rowMeta,
        rowCache: rowCache,
      ),
      cellBuilder: EditableCellBuilder(databaseController: databaseController),
      openDetailPage: (rowDetailContext) => FlowyOverlay.show(
        context: rowDetailContext,
        builder: (_) {
          final rowMeta = rowCache.getRow(rowId)?.rowMeta;
          if (rowMeta == null) {
            return const SizedBox.shrink();
          }

          return BlocProvider.value(
            value: context.read<ViewBloc>(),
            child: RowDetailPage(
              rowController: RowController(
                viewId: viewId,
                rowMeta: rowMeta,
                rowCache: rowCache,
              ),
              databaseController: databaseController,
              userProfile: context.read<GridBloc>().userProfile,
            ),
          );
        },
      ),
    );

    if (animation != null) {
      return SizeTransition(sizeFactor: animation, child: child);
    }

    return child;
  }

  void moveRow(int from, int to) {
    if (from != to) {
      context.read<GridBloc>().add(GridEvent.moveRow(from, to));
    }
  }
}

class _WrapScrollView extends StatelessWidget {
  const _WrapScrollView({
    required this.contentWidth,
    required this.scrollController,
    required this.child,
  });

  final GridScrollController scrollController;
  final double contentWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ScrollbarListStack(
      includeInsets: false,
      axis: Axis.vertical,
      controller: scrollController.verticalController,
      barSize: GridSize.scrollBarSize,
      autoHideScrollbar: false,
      child: StyledSingleChildScrollView(
        autoHideScrollbar: false,
        includeInsets: false,
        controller: scrollController.horizontalController,
        axis: Axis.horizontal,
        child: SizedBox(
          width: contentWidth,
          child: child,
        ),
      ),
    );
  }
}

/// This Widget is used to show the Calculations Row at the bottom of the Grids ScrollView
/// when the ScrollView is scrollable.
///
class _PositionedCalculationsRow extends StatefulWidget {
  const _PositionedCalculationsRow({
    required this.viewId,
    this.isAtBottom = false,
  });

  final String viewId;

  /// We don't need to show the top border if the scroll offset
  /// is at the bottom of the ScrollView.
  ///
  final bool isAtBottom;

  @override
  State<_PositionedCalculationsRow> createState() =>
      _PositionedCalculationsRowState();
}

class _PositionedCalculationsRowState
    extends State<_PositionedCalculationsRow> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        left: context.read<DatabasePluginWidgetBuilderSize>().horizontalPadding,
      ),
      padding: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).canvasColor,
        border: widget.isAtBottom
            ? null
            : Border(
                top: BorderSide(
                  color: AFThemeExtension.of(context).borderColor,
                ),
              ),
      ),
      child: SizedBox(
        height: 36,
        width: double.infinity,
        child: GridCalculationsRow(
          key: const Key('floating_grid_calculations'),
          viewId: widget.viewId,
          includeDefaultInsets: false,
        ),
      ),
    );
  }
}
