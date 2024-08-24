import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/calculations_row.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/toolbar/grid_setting_bar.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/setting_menu.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy/workspace/application/action_navigation/navigation_action.dart';
import 'package:appflowy/workspace/application/view/view_bloc.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

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
  });

  final ViewPB view;
  final DatabaseController databaseController;
  final VoidCallback? onDeleted;
  final String? initialRowId;

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  bool _didOpenInitialRow = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GridBloc>(
      create: (context) => GridBloc(
        view: widget.view,
        databaseController: widget.databaseController,
      )..add(const GridEvent.initial()),
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
          listener: (context, state) => state.loadingState.whenOrNull(
            // If initial row id is defined, open row details overlay
            finish: (_) {
              if (widget.initialRowId != null && !_didOpenInitialRow) {
                _didOpenInitialRow = true;

                _openRow(context, widget.initialRowId!);
              }

              return;
            },
          ),
          builder: (context, state) => state.loadingState.map(
            loading: (_) =>
                const Center(child: CircularProgressIndicator.adaptive()),
            finish: (result) => result.successOrFail.fold(
              (_) => GridShortcuts(
                child: GridPageContent(
                  key: ValueKey(widget.view.id),
                  view: widget.view,
                ),
              ),
              (err) => FlowyErrorPage.message(
                err.toString(),
                howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
              ),
            ),
            idle: (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  void _openRow(
    BuildContext context,
    String rowId,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gridBloc = context.read<GridBloc>();
      final rowCache = gridBloc.getRowCache(rowId);
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
          ),
        ),
      );
    });
  }
}

class GridPageContent extends StatefulWidget {
  const GridPageContent({
    super.key,
    required this.view,
  });

  final ViewPB view;

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
      children: [
        _GridHeader(
          headerScrollController: headerScrollController,
        ),
        _GridRows(
          viewId: widget.view.id,
          scrollController: _scrollController,
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
      builder: (context, state) {
        return GridHeaderSliverAdaptor(
          viewId: state.viewId,
          anchorScrollController: headerScrollController,
        );
      },
    );
  }
}

class _GridRows extends StatefulWidget {
  const _GridRows({
    required this.viewId,
    required this.scrollController,
  });

  final String viewId;
  final GridScrollController scrollController;

  @override
  State<_GridRows> createState() => _GridRowsState();
}

class _GridRowsState extends State<_GridRows> {
  bool showFloatingCalculations = false;

  @override
  void initState() {
    super.initState();
    _evaluateFloatingCalculations();
  }

  void _evaluateFloatingCalculations() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        // maxScrollExtent is 0.0 if scrolling is not possible
        showFloatingCalculations = widget
                .scrollController.verticalController.position.maxScrollExtent >
            0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridBloc, GridState>(
      buildWhen: (previous, current) => previous.fields != current.fields,
      builder: (context, state) {
        return Flexible(
          child: _WrapScrollView(
            scrollController: widget.scrollController,
            contentWidth: GridLayout.headerWidth(state.fields),
            child: BlocConsumer<GridBloc, GridState>(
              listenWhen: (previous, current) =>
                  previous.rowCount != current.rowCount,
              listener: (context, state) => _evaluateFloatingCalculations(),
              builder: (context, state) {
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    scrollbars: false,
                  ),
                  child: _renderList(context, state),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _renderList(
    BuildContext context,
    GridState state,
  ) {
    // 1. GridRowBottomBar
    // 2. GridCalculationsRow
    // 3. Footer Padding
    final itemCount = state.rowInfos.length + 3;

    return Stack(
      children: [
        Positioned.fill(
          child: ReorderableListView.builder(
            ///  This is a workaround related to
            ///  https://github.com/flutter/flutter/issues/25652
            // cacheExtent: 5000,
            scrollController: widget.scrollController.verticalController,
            physics: const ClampingScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.white.withOpacity(.1),
              child: Opacity(opacity: .5, child: child),
            ),
            onReorder: (fromIndex, newIndex) {
              final toIndex = newIndex > fromIndex ? newIndex - 1 : newIndex;
              if (fromIndex != toIndex) {
                context
                    .read<GridBloc>()
                    .add(GridEvent.moveRow(fromIndex, toIndex));
              }
            },
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index < state.rowInfos.length) {
                return _renderRow(
                  context,
                  state.rowInfos[index].rowId,
                  isDraggable: state.reorderable,
                  index: index,
                );
              }

              if (index == state.rowInfos.length) {
                return const GridRowBottomBar(key: Key('grid_footer'));
              }

              if (index == state.rowInfos.length + 1) {
                if (showFloatingCalculations) {
                  return const SizedBox(
                    key: Key('calculations_bottom_padding'),
                    height: 36,
                  );
                } else {
                  return GridCalculationsRow(
                    key: const Key('grid_calculations'),
                    viewId: widget.viewId,
                  );
                }
              }

              return const SizedBox(key: Key('footer_padding'), height: 10);
            },
          ),
        ),
        if (showFloatingCalculations) ...[
          _PositionedCalculationsRow(viewId: widget.viewId),
        ],
      ],
    );
  }

  Widget _renderRow(
    BuildContext context,
    RowId rowId, {
    int? index,
    required bool isDraggable,
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
    final rowController = RowController(
      viewId: viewId,
      rowMeta: rowMeta,
      rowCache: rowCache,
    );

    final child = GridRow(
      key: ValueKey(rowId),
      fieldController: databaseController.fieldController,
      rowId: rowId,
      viewId: viewId,
      index: index,
      isDraggable: isDraggable,
      rowController: rowController,
      cellBuilder: EditableCellBuilder(databaseController: databaseController),
      openDetailPage: (rowDetailContext) {
        FlowyOverlay.show(
          context: rowDetailContext,
          builder: (_) => BlocProvider.value(
            value: context.read<ViewBloc>(),
            child: RowDetailPage(
              rowController: rowController,
              databaseController: databaseController,
            ),
          ),
        );
      },
    );

    if (animation != null) {
      return SizeTransition(sizeFactor: animation, child: child);
    }

    return child;
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
  });

  final String viewId;

  @override
  State<_PositionedCalculationsRow> createState() =>
      _PositionedCalculationsRowState();
}

class _PositionedCalculationsRowState
    extends State<_PositionedCalculationsRow> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: EdgeInsets.only(
          left:
              context.read<DatabasePluginWidgetBuilderSize>().horizontalPadding,
        ),
        padding: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).canvasColor,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
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
      ),
    );
  }
}
