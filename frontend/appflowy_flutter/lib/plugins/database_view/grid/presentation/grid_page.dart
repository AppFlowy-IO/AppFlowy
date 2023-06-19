import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy_backend/log.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../application/field/field_controller.dart';
import '../../application/row/row_cache.dart';
import '../../application/row/row_data_controller.dart';
import '../../application/setting/setting_bloc.dart';
import '../application/filter/filter_menu_bloc.dart';
import '../application/grid_bloc.dart';
import '../../application/database_controller.dart';
import '../application/sort/sort_menu_bloc.dart';
import 'grid_scroll.dart';
import 'layout/layout.dart';
import 'layout/sizes.dart';
import 'widgets/accessory_menu.dart';
import 'widgets/row/row.dart';
import 'widgets/footer/grid_footer.dart';
import 'widgets/header/grid_header.dart';
import '../../widgets/row/row_detail.dart';
import 'widgets/shortcuts.dart';
import 'widgets/toolbar/grid_toolbar.dart';

class GridPage extends StatefulWidget {
  const GridPage({
    required this.view,
    this.onDeleted,
    Key? key,
  }) : super(key: key);

  final ViewPB view;
  final VoidCallback? onDeleted;

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  late DatabaseController databaseController;

  @override
  void initState() {
    super.initState();
    databaseController = DatabaseController(view: widget.view);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GridBloc>(
          create: (context) => GridBloc(
            view: widget.view,
            databaseController: databaseController,
          )..add(const GridEvent.initial()),
        ),
        BlocProvider<GridFilterMenuBloc>(
          create: (context) => GridFilterMenuBloc(
            viewId: widget.view.id,
            fieldController: databaseController.fieldController,
          )..add(const GridFilterMenuEvent.initial()),
        ),
        BlocProvider<SortMenuBloc>(
          create: (context) => SortMenuBloc(
            viewId: widget.view.id,
            fieldController: databaseController.fieldController,
          )..add(const SortMenuEvent.initial()),
        ),
        BlocProvider<DatabaseSettingBloc>(
          create: (context) => DatabaseSettingBloc(viewId: widget.view.id),
        ),
      ],
      child: BlocBuilder<GridBloc, GridState>(
        builder: (context, state) {
          return state.loadingState.map(
            loading: (_) =>
                const Center(child: CircularProgressIndicator.adaptive()),
            finish: (result) => result.successOrFail.fold(
              (_) => GridShortcuts(
                child: FlowyGrid(
                  viewId: widget.view.id,
                ),
              ),
              (err) => FlowyErrorPage(err.toString()),
            ),
          );
        },
      ),
    );
  }
}

class FlowyGrid extends StatefulWidget {
  final String viewId;
  const FlowyGrid({
    required this.viewId,
    super.key,
  });

  @override
  State<FlowyGrid> createState() => _FlowyGridState();
}

class _FlowyGridState extends State<FlowyGrid> {
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
    return BlocBuilder<GridBloc, GridState>(
      buildWhen: (previous, current) => previous.fields != current.fields,
      builder: (context, state) {
        final contentWidth = GridLayout.headerWidth(state.fields.value);
        final child = _WrapScrollView(
          scrollController: _scrollController,
          contentWidth: contentWidth,
          child: _GridRows(
            viewId: widget.viewId,
            verticalScrollController: _scrollController.verticalController,
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GridToolbar(),
            GridAccessoryMenu(viewId: state.viewId),
            _gridHeader(context, state.viewId),
            Flexible(child: child),
            const _RowCountBadge(),
          ],
        );
      },
    );
  }

  Widget _gridHeader(BuildContext context, String viewId) {
    final fieldController =
        context.read<GridBloc>().databaseController.fieldController;
    return GridHeaderSliverAdaptor(
      viewId: viewId,
      fieldController: fieldController,
      anchorScrollController: headerScrollController,
    );
  }
}

class _GridRows extends StatelessWidget {
  final String viewId;
  const _GridRows({
    required this.viewId,
    required this.verticalScrollController,
  });

  final ScrollController verticalScrollController;

  @override
  Widget build(BuildContext context) {
    final filterState = context.watch<GridFilterMenuBloc>().state;
    final sortState = context.watch<SortMenuBloc>().state;

    return BlocBuilder<GridBloc, GridState>(
      buildWhen: (previous, current) => current.reason.maybeWhen(
        reorderRows: () => true,
        reorderSingleRow: (reorderRow, rowInfo) => true,
        delete: (item) => true,
        insert: (item) => true,
        orElse: () => false,
      ),
      builder: (context, state) {
        final rowInfos = state.rowInfos;
        final behavior = ScrollConfiguration.of(context).copyWith(
          scrollbars: false,
        );
        return ScrollConfiguration(
          behavior: behavior,
          child: ReorderableListView.builder(
            /// TODO(Xazin): Resolve inconsistent scrollbar behavior
            ///  This is a workaround related to
            ///  https://github.com/flutter/flutter/issues/25652
            cacheExtent: 5000,
            scrollController: verticalScrollController,
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) => Material(
              color: Colors.white.withOpacity(.1),
              child: Opacity(opacity: .5, child: child),
            ),
            onReorder: (fromIndex, newIndex) {
              final toIndex = newIndex > fromIndex ? newIndex - 1 : newIndex;
              if (fromIndex == toIndex) {
                return;
              }
              context
                  .read<GridBloc>()
                  .add(GridEvent.moveRow(fromIndex, toIndex));
            },
            itemCount: rowInfos.length + 1, // the extra item is the footer
            itemBuilder: (context, index) {
              if (index < rowInfos.length) {
                final rowInfo = rowInfos[index];
                return _renderRow(
                  context,
                  rowInfo.rowId,
                  index: index,
                  isSortEnabled: sortState.sortInfos.isNotEmpty,
                  isFilterEnabled: filterState.filters.isNotEmpty,
                );
              }
              return const _GridFooter(key: Key('gridFooter'));
            },
          ),
        );
      },
    );
  }

  Widget _renderRow(
    BuildContext context,
    RowId rowId, {
    int? index,
    bool isSortEnabled = false,
    bool isFilterEnabled = false,
    Animation<double>? animation,
  }) {
    final rowCache = context.read<GridBloc>().getRowCache(rowId);
    final rowMeta = rowCache.getRow(rowId)?.rowMeta;

    /// Return placeholder widget if the rowMeta is null.
    if (rowMeta == null) return const SizedBox.shrink();

    final fieldController =
        context.read<GridBloc>().databaseController.fieldController;
    final dataController = RowController(
      viewId: viewId,
      rowMeta: rowMeta,
      rowCache: rowCache,
    );

    final child = GridRow(
      key: ValueKey(rowMeta.id),
      rowId: rowId,
      viewId: viewId,
      index: index,
      isDraggable: !isSortEnabled && !isFilterEnabled,
      dataController: dataController,
      cellBuilder: GridCellBuilder(cellCache: dataController.cellCache),
      openDetailPage: (context, cellBuilder) {
        _openRowDetailPage(
          context,
          rowId,
          fieldController,
          rowCache,
          cellBuilder,
        );
      },
    );

    if (animation != null) {
      return SizeTransition(
        sizeFactor: animation,
        child: child,
      );
    }

    return child;
  }

  void _openRowDetailPage(
    BuildContext context,
    RowId rowId,
    FieldController fieldController,
    RowCache rowCache,
    GridCellBuilder cellBuilder,
  ) {
    final rowMeta = rowCache.getRow(rowId)?.rowMeta;
    // Most of the cases, the rowMeta should not be null.
    if (rowMeta != null) {
      final dataController = RowController(
        viewId: viewId,
        rowMeta: rowMeta,
        rowCache: rowCache,
      );

      FlowyOverlay.show(
        context: context,
        builder: (BuildContext context) {
          return RowDetailPage(
            cellBuilder: cellBuilder,
            rowController: dataController,
          );
        },
      );
    } else {
      Log.warn('RowMeta is null for rowId: $rowId');
    }
  }
}

class _GridFooter extends StatelessWidget {
  const _GridFooter({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: GridSize.footerContentInsets,
      height: GridSize.footerHeight,
      margin: const EdgeInsets.only(bottom: 200),
      child: const GridAddRowButton(),
    );
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
      axis: Axis.vertical,
      controller: scrollController.verticalController,
      barSize: GridSize.scrollBarSize,
      autoHideScrollbar: false,
      child: StyledSingleChildScrollView(
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

class _RowCountBadge extends StatelessWidget {
  const _RowCountBadge();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GridBloc, GridState, int>(
      selector: (state) => state.rowCount,
      builder: (context, rowCount) {
        return Padding(
          padding: GridSize.footerContentInsets,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              FlowyText.medium(
                rowCountString(rowCount),
                color: Theme.of(context).hintColor,
              ),
            ],
          ),
        );
      },
    );
  }
}

String rowCountString(int count) {
  return '${LocaleKeys.grid_row_count.tr()} : $count';
}
