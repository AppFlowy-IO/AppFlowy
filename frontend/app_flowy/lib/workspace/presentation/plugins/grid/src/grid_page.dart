import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/grid_bloc.dart';
import 'package:app_flowy/workspace/application/grid/row/row_service.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/log.dart';
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
              (_) => const FlowyGrid(),
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
  _FlowyGridState createState() => _FlowyGridState();
}

class _FlowyGridState extends State<FlowyGrid> {
  final _scrollController = GridScrollController();
  final _key = GlobalKey<SliverAnimatedListState>();

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
        if (state.fields.isEmpty) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final child = SizedBox(
          width: GridLayout.headerWidth(state.fields),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: CustomScrollView(
              physics: StyledScrollPhysics(),
              controller: _scrollController.verticalController,
              slivers: [
                _renderToolbar(state.gridId),
                _renderGridHeader(state.gridId),
                _renderRows(gridId: state.gridId, context: context),
                const GridFooter(),
              ],
            ),
          ),
        );

        return _wrapScrollbar(child);
      },
    );
  }

  Widget _wrapScrollbar(Widget child) {
    return ScrollbarListStack(
      axis: Axis.vertical,
      controller: _scrollController.verticalController,
      barSize: GridSize.scrollBarSize,
      child: StyledSingleChildScrollView(
        controller: _scrollController.horizontalController,
        axis: Axis.horizontal,
        child: child,
      ),
    );
  }

  Widget _renderGridHeader(String gridId) {
    return BlocSelector<GridBloc, GridState, List<Field>>(
      selector: (state) => state.fields,
      builder: (context, fields) {
        return GridHeader(gridId: gridId, fields: List.from(fields));
      },
    );
  }

  Widget _renderToolbar(String gridId) {
    return BlocSelector<GridBloc, GridState, List<Field>>(
      selector: (state) => state.fields,
      builder: (context, fields) {
        final toolbarContext = GridToolbarContext(
          gridId: gridId,
          fields: fields,
        );

        return SliverToBoxAdapter(
          child: GridToolbar(toolbarContext: toolbarContext),
        );
      },
    );
  }

  Widget _renderRows({required String gridId, required BuildContext context}) {
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
