import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/grid_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart' show Field;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'controller/grid_scroll.dart';
import 'layout/layout.dart';
import 'layout/sizes.dart';
import 'widgets/row/grid_row.dart';
import 'widgets/footer/grid_footer.dart';
import 'widgets/header/grid_header.dart';
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
              (_) => FlowyGrid(),
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

class FlowyGrid extends StatelessWidget {
  final _scrollController = GridScrollController();
  FlowyGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridBloc, GridState>(
      buildWhen: (previous, current) => previous.fields.length != current.fields.length,
      builder: (context, state) {
        final child = _wrapScrollView(
          state.fields,
          [
            _GridHeader(gridId: state.gridId, fields: List.from(state.fields)),
            _GridRows(),
            const _GridFooter(),
          ],
        );

        return Column(children: [
          const _GridToolbarAdaptor(),
          Flexible(child: child),
        ]);
      },
    );
  }

  Widget _wrapScrollView(
    List<Field> fields,
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
      width: GridLayout.headerWidth(fields),
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
}

class _GridToolbarAdaptor extends StatelessWidget {
  const _GridToolbarAdaptor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GridBloc, GridState, GridToolbarContext>(
      selector: (state) {
        return GridToolbarContext(
          gridId: state.gridId,
          fields: state.fields,
        );
      },
      builder: (context, toolbarContext) {
        return GridToolbar(toolbarContext: toolbarContext);
      },
    );
  }
}

class _GridHeader extends StatelessWidget {
  final String gridId;
  final List<Field> fields;
  const _GridHeader({Key? key, required this.gridId, required this.fields}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      delegate: GridHeaderSliverAdaptor(gridId: gridId, fields: List.from(fields)),
      floating: true,
      pinned: true,
    );
  }
}

class _GridRows extends StatelessWidget {
  final _key = GlobalKey<SliverAnimatedListState>();
  _GridRows({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GridBloc, GridState>(
      listener: (context, state) {
        state.listState.map(
          insert: (value) {
            for (final index in value.indexs) {
              _key.currentState?.insertItem(index);
            }
          },
          delete: (value) {
            for (final index in value.indexs) {
              _key.currentState?.removeItem(index.value1, (context, animation) => _renderRow(index.value2, animation));
            }
          },
          reload: (updatedIndexs) {},
        );
      },
      buildWhen: (previous, current) => false,
      builder: (context, state) {
        return SliverAnimatedList(
          key: _key,
          initialItemCount: context.read<GridBloc>().state.rows.length,
          itemBuilder: (BuildContext context, int index, Animation<double> animation) {
            final rowData = context.read<GridBloc>().state.rows[index];
            return _renderRow(rowData, animation);
          },
        );
      },
    );
  }

  Widget _renderRow(RowData rowData, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: GridRowWidget(data: rowData, key: ValueKey(rowData.rowId)),
    );
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
