import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/grid_bloc.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scroll_bar.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flowy_sdk/protobuf/flowy-folder-data-model/view.pb.dart';
import 'package:flowy_sdk/protobuf/flowy-grid-data-model/grid.pb.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:styled_widget/styled_widget.dart';

import 'controller/grid_scroll.dart';
import 'layout/layout.dart';
import 'layout/sizes.dart';
import 'widgets/content/grid_row.dart';
import 'widgets/footer/grid_footer.dart';
import 'widgets/header/header.dart';

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

        return _wrapScrollbar(state.fields, [
          _buildHeader(gridId, state.fields),
          _buildRows(context),
          const GridFooter(),
        ]);
      },
    );
  }

  Widget _wrapScrollbar(List<Field> fields, List<Widget> children) {
    return ScrollbarListStack(
      axis: Axis.vertical,
      controller: _scrollController.verticalController,
      barSize: GridSize.scrollBarSize,
      child: StyledSingleChildScrollView(
        controller: _scrollController.horizontalController,
        axis: Axis.horizontal,
        child: SizedBox(
          width: GridLayout.headerWidth(fields),
          child: ScrollConfiguration(
            behavior: const ScrollBehavior().copyWith(scrollbars: false),
            child: CustomScrollView(
              physics: StyledScrollPhysics(),
              controller: _scrollController.verticalController,
              slivers: <Widget>[...children],
            ),
          ),
        ),
      ),
    ).padding(right: 0, top: GridSize.headerHeight, bottom: GridSize.scrollBarSize);
  }

  Widget _buildHeader(String gridId, List<Field> fields) {
    return SliverPersistentHeader(
      delegate: GridHeaderDelegate(gridId: gridId, fields: fields),
      floating: true,
      pinned: true,
    );
  }

  Widget _buildRows(BuildContext context) {
    return BlocBuilder<GridBloc, GridState>(
      buildWhen: (previous, current) => previous.rows.length != current.rows.length,
      builder: (context, state) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final rowData = context.read<GridBloc>().state.rows[index];
              return GridRowWidget(data: rowData);
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
