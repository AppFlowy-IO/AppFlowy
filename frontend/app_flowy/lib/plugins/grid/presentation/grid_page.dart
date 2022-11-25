import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:app_flowy/plugins/grid/application/field/field_controller.dart';
import 'package:app_flowy/plugins/grid/application/filter/filter_menu_bloc.dart';
import 'package:app_flowy/plugins/grid/application/grid_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/row/row_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/grid_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../application/row/row_cache.dart';
import '../application/setting/setting_bloc.dart';
import 'controller/grid_scroll.dart';
import 'layout/layout.dart';
import 'layout/sizes.dart';
import 'widgets/cell/cell_builder.dart';
import 'widgets/row/grid_row.dart';
import 'widgets/footer/grid_footer.dart';
import 'widgets/header/grid_header.dart';
import 'widgets/row/row_detail.dart';
import 'widgets/shortcuts.dart';
import 'widgets/filter/menu.dart';
import 'widgets/toolbar/grid_toolbar.dart';

class GridPage extends StatefulWidget {
  final ViewPB view;
  final GridController gridController;
  final VoidCallback? onDeleted;

  GridPage({
    required this.view,
    this.onDeleted,
    Key? key,
  })  : gridController = GridController(view: view),
        super(key: key);

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GridBloc>(
          create: (context) => GridBloc(
            view: widget.view,
            gridController: widget.gridController,
          )..add(const GridEvent.initial()),
        ),
        BlocProvider<GridFilterMenuBloc>(
          create: (context) => GridFilterMenuBloc(
            viewId: widget.view.id,
            fieldController: widget.gridController.fieldController,
          )..add(const GridFilterMenuEvent.initial()),
        ),
        BlocProvider<GridSettingBloc>(
          create: (context) => GridSettingBloc(gridId: widget.view.id),
        ),
      ],
      child: BlocBuilder<GridBloc, GridState>(
        builder: (context, state) {
          return state.loadingState.map(
            loading: (_) =>
                const Center(child: CircularProgressIndicator.adaptive()),
            finish: (result) => result.successOrFail.fold(
              (_) => const GridShortcuts(child: FlowyGrid()),
              (err) => FlowyErrorPage(err.toString()),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  void didUpdateWidget(covariant GridPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
}

class FlowyGrid extends StatefulWidget {
  const FlowyGrid({Key? key}) : super(key: key);

  @override
  State<FlowyGrid> createState() => _FlowyGridState();
}

class _FlowyGridState extends State<FlowyGrid> {
  final _scrollController = GridScrollController(
      scrollGroupController: LinkedScrollControllerGroup());
  late ScrollController headerScrollController;

  @override
  void initState() {
    headerScrollController = _scrollController.linkHorizontalController();
    super.initState();
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
        final child = _wrapScrollView(
          contentWidth,
          [
            const _GridRows(),
            const _GridFooter(),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GridToolbar(),
            const GridFilterMenu(),
            _gridHeader(context, state.gridId),
            Flexible(child: child),
            const RowCountBadge(),
          ],
        );
      },
    );
  }

  Widget _wrapScrollView(
    double contentWidth,
    List<Widget> slivers,
  ) {
    final verticalScrollView = ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: CustomScrollView(
        physics: StyledScrollPhysics(),
        controller: _scrollController.verticalController,
        slivers: slivers,
      ),
    );

    final sizedVerticalScrollView = SizedBox(
      width: contentWidth,
      child: verticalScrollView,
    );

    final horizontalScrollView = StyledSingleChildScrollView(
      controller: _scrollController.horizontalController,
      axis: Axis.horizontal,
      child: sizedVerticalScrollView,
    );

    return ScrollbarListStack(
      axis: Axis.vertical,
      controller: _scrollController.verticalController,
      barSize: GridSize.scrollBarSize,
      child: horizontalScrollView,
    );
  }

  Widget _gridHeader(BuildContext context, String gridId) {
    final fieldController =
        context.read<GridBloc>().gridController.fieldController;
    return GridHeaderSliverAdaptor(
      gridId: gridId,
      fieldController: fieldController,
      anchorScrollController: headerScrollController,
    );
  }
}

class _GridRows extends StatefulWidget {
  const _GridRows({Key? key}) : super(key: key);

  @override
  State<_GridRows> createState() => _GridRowsState();
}

class _GridRowsState extends State<_GridRows> {
  final _key = GlobalKey<SliverAnimatedListState>();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GridBloc, GridState>(
      // listenWhen: (previous, current) => previous.reason != current.reason,
      listener: (context, state) {
        state.reason.mapOrNull(
          insert: (value) {
            for (final item in value.items) {
              _key.currentState?.insertItem(item.index);
            }
          },
          delete: (value) {
            for (final item in value.items) {
              _key.currentState?.removeItem(
                item.index,
                (context, animation) =>
                    _renderRow(context, item.row, animation),
              );
            }
          },
        );
      },
      buildWhen: (previous, current) => false,
      builder: (context, state) {
        return SliverAnimatedList(
          key: _key,
          initialItemCount: context.read<GridBloc>().state.rowInfos.length,
          itemBuilder:
              (BuildContext context, int index, Animation<double> animation) {
            final RowInfo rowInfo =
                context.read<GridBloc>().state.rowInfos[index];
            return _renderRow(context, rowInfo, animation);
          },
        );
      },
    );
  }

  Widget _renderRow(
    BuildContext context,
    RowInfo rowInfo,
    Animation<double> animation,
  ) {
    final rowCache = context.read<GridBloc>().getRowCache(
          rowInfo.rowPB.blockId,
          rowInfo.rowPB.id,
        );

    /// Return placeholder widget if the rowCache is null.
    if (rowCache == null) return const SizedBox();

    final fieldController =
        context.read<GridBloc>().gridController.fieldController;
    final dataController = GridRowDataController(
      rowInfo: rowInfo,
      fieldController: fieldController,
      rowCache: rowCache,
    );

    return SizeTransition(
      sizeFactor: animation,
      child: GridRowWidget(
        rowInfo: rowInfo,
        dataController: dataController,
        cellBuilder: GridCellBuilder(delegate: dataController),
        openDetailPage: (context, cellBuilder) {
          _openRowDetailPage(
            context,
            rowInfo,
            fieldController,
            rowCache,
            cellBuilder,
          );
        },
        key: ValueKey(rowInfo.rowPB.id),
      ),
    );
  }

  void _openRowDetailPage(
    BuildContext context,
    RowInfo rowInfo,
    GridFieldController fieldController,
    GridRowCache rowCache,
    GridCellBuilder cellBuilder,
  ) {
    final dataController = GridRowDataController(
      rowInfo: rowInfo,
      fieldController: fieldController,
      rowCache: rowCache,
    );

    FlowyOverlay.show(
        context: context,
        builder: (BuildContext context) {
          return RowDetailPage(
            cellBuilder: cellBuilder,
            dataController: dataController,
          );
        });
  }
}

class _GridFooter extends StatelessWidget {
  const _GridFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 200),
      sliver: SliverToBoxAdapter(
        child: SizedBox(
          height: GridSize.footerHeight,
          child: Padding(
            padding: GridSize.footerContentInsets,
            child: const SizedBox(height: 40, child: GridAddRowButton()),
          ),
        ),
      ),
    );
  }
}

class RowCountBadge extends StatelessWidget {
  const RowCountBadge({Key? key}) : super(key: key);

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
              FlowyText.regular(
                '${LocaleKeys.grid_row_count.tr()} : ',
                fontSize: 13,
                color: Theme.of(context).hintColor,
              ),
              FlowyText.regular(rowCount.toString(), fontSize: 13),
            ],
          ),
        );
      },
    );
  }
}
