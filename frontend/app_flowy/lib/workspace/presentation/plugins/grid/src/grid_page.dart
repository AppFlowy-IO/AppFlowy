import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/grid_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder/view.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'controller/grid_scroll.dart';
import 'layout/layout.dart';
import 'layout/sizes.dart';
import 'widgets/row/grid_row.dart';
import 'widgets/footer/grid_footer.dart';
import 'widgets/header/grid_header.dart';
import 'widgets/shortcuts.dart';
import 'widgets/toolbar/grid_toolbar.dart';

class GridPage extends StatefulWidget {
  final View view;

  GridPage({Key? key, required this.view}) : super(key: ValueKey(view.id));

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GridBloc>(
          create: (context) => getIt<GridBloc>(param1: widget.view)..add(const GridEvent.initial()),
        ),
      ],
      child: BlocBuilder<GridBloc, GridState>(
        builder: (context, state) {
          return state.loadingState.map(
            loading: (_) => const Center(child: CircularProgressIndicator.adaptive()),
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
  final _scrollController = GridScrollController(scrollGroupContorller: LinkedScrollControllerGroup());
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
            const _GridToolbarAdaptor(),
            _gridHeader(context, state.gridId),
            Flexible(child: child),
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
    final fieldCache = context.read<GridBloc>().fieldCache;
    return GridHeaderSliverAdaptor(
      gridId: gridId,
      fieldCache: fieldCache,
      anchorScrollController: headerScrollController,
    );
  }
}

class _GridToolbarAdaptor extends StatelessWidget {
  const _GridToolbarAdaptor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GridBloc, GridState, GridToolbarContext>(
      selector: (state) {
        final fieldCache = context.read<GridBloc>().fieldCache;
        return GridToolbarContext(
          gridId: state.gridId,
          fieldCache: fieldCache,
        );
      },
      builder: (context, toolbarContext) {
        return GridToolbar(toolbarContext: toolbarContext);
      },
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
      listenWhen: (previous, current) => previous.reason != current.reason,
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
                (context, animation) => _renderRow(context, item.row, animation),
              );
            }
          },
        );
      },
      buildWhen: (previous, current) => false,
      builder: (context, state) {
        return SliverAnimatedList(
          key: _key,
          initialItemCount: context.read<GridBloc>().state.rows.length,
          itemBuilder: (BuildContext context, int index, Animation<double> animation) {
            final GridRow rowData = context.read<GridBloc>().state.rows[index];
            return _renderRow(context, rowData, animation);
          },
        );
      },
    );
  }

  Widget _renderRow(
    BuildContext context,
    GridRow rowData,
    Animation<double> animation,
  ) {
    final rowCache = context.read<GridBloc>().getRowCache(rowData.blockId, rowData.rowId);
    final fieldCache = context.read<GridBloc>().fieldCache;
    if (rowCache != null) {
      return SizeTransition(
        sizeFactor: animation,
        child: GridRowWidget(
          rowData: rowData,
          rowCache: rowCache,
          fieldCache: fieldCache,
          key: ValueKey(rowData.rowId),
        ),
      );
    } else {
      return const SizedBox();
    }
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
            padding: GridSize.headerContentInsets,
            child: Row(
              children: [
                SizedBox(width: GridSize.leadingHeaderPadding),
                const SizedBox(width: 120, child: GridAddRowButton()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
