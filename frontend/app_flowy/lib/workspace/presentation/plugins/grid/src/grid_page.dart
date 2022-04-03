import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/grid_bloc.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
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

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gridId = context.read<GridBloc>().view.id;

    return BlocBuilder<GridBloc, GridState>(
      buildWhen: (previous, current) => previous.fields != current.fields,
      builder: (context, state) {
        if (state.fields.isEmpty) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }

        final child = BlocBuilder<GridBloc, GridState>(
          builder: (context, state) {
            return SizedBox(
              width: GridLayout.headerWidth(state.fields),
              child: ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: false),
                child: CustomScrollView(
                  physics: StyledScrollPhysics(),
                  controller: _scrollController.verticalController,
                  slivers: [
                    _renderToolbar(gridId),
                    GridHeader(gridId: gridId, fields: List.from(state.fields)),
                    _renderRows(context),
                    const GridFooter(),
                  ],
                ),
              ),
            );
          },
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

  Widget _renderToolbar(String gridId) {
    return BlocBuilder<GridBloc, GridState>(
      builder: (context, state) {
        final toolbarContext = GridToolbarContext(
          gridId: gridId,
          fields: state.fields,
        );

        return SliverToBoxAdapter(
          child: GridToolbar(toolbarContext: toolbarContext),
        );
      },
    );
  }

  Widget _renderRows(BuildContext context) {
    return BlocBuilder<GridBloc, GridState>(
      buildWhen: (previous, current) {
        final rowChanged = previous.rows.length != current.rows.length;
        // final fieldChanged = previous.fields.length != current.fields.length;
        return rowChanged;
      },
      builder: (context, state) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final blockRow = context.read<GridBloc>().state.rows[index];
              final fields = context.read<GridBloc>().state.fields;
              final rowData = GridRowData.fromBlockRow(blockRow, fields);
              return GridRowWidget(data: rowData, key: ValueKey(rowData.rowId));
            },
            childCount: context.read<GridBloc>().state.rows.length,
            addRepaintBoundaries: true,
            addAutomaticKeepAlives: true,
          ),
        );
      },
    );
  }
}
