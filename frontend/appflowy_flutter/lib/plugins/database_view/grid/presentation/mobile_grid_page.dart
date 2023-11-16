import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy/plugins/database_view/grid/application/grid_bloc.dart';
import 'package:appflowy/plugins/database_view/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

import 'grid_page.dart';
import 'grid_scroll.dart';
import 'layout/layout.dart';
import 'layout/sizes.dart';
import 'widgets/footer/grid_footer.dart';
import 'widgets/header/grid_header.dart';
import 'widgets/row/row.dart';
import 'widgets/shortcuts.dart';
import 'widgets/toolbar/mobile_grid_setting.dart';

class MobileGridTabBarBuilderImpl implements DatabaseTabBarItemBuilder {
  final _toggleExtension = ToggleExtensionNotifier();

  @override
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
    bool shrinkWrap,
  ) {
    return MobileGridPage(
      key: _makeValueKey(controller),
      view: view,
      databaseController: controller,
    );
  }

  @override
  Widget settingBar(BuildContext context, DatabaseController controller) {
    return MobileGridSettingButton(
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
    return const SizedBox.shrink();
  }

  ValueKey _makeValueKey(DatabaseController controller) {
    return ValueKey(controller.viewId);
  }
}

class MobileGridPage extends StatefulWidget {
  final DatabaseController databaseController;
  const MobileGridPage({
    required this.view,
    required this.databaseController,
    this.onDeleted,
    Key? key,
  }) : super(key: key);

  final ViewPB view;
  final VoidCallback? onDeleted;

  @override
  State<MobileGridPage> createState() => _MobileGridPageState();
}

class _MobileGridPageState extends State<MobileGridPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<GridBloc>(
          create: (context) => GridBloc(
            view: widget.view,
            databaseController: widget.databaseController,
          )..add(const GridEvent.initial()),
        ),
      ],
      child: BlocBuilder<GridBloc, GridState>(
        builder: (context, state) {
          return state.loadingState.map(
            loading: (_) =>
                const Center(child: CircularProgressIndicator.adaptive()),
            finish: (result) => result.successOrFail.fold(
              (_) => GridShortcuts(
                child: GridPageContent(view: widget.view),
              ),
              (err) => FlowyErrorPage.message(
                err.toString(),
                howToFix: LocaleKeys.errorDialog_howToFixFallback.tr(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class GridPageContent extends StatefulWidget {
  final ViewPB view;
  const GridPageContent({
    required this.view,
    super.key,
  });

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
    return BlocBuilder<GridBloc, GridState>(
      buildWhen: (previous, current) => previous.fields != current.fields,
      builder: (context, state) {
        final contentWidth = GridLayout.headerWidth(state.fields.fields);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child:
                  _GridHeader(headerScrollController: headerScrollController),
            ),
            _GridRows(
              viewId: state.viewId,
              contentWidth: contentWidth,
              scrollController: _scrollController,
            ),
          ],
        );
      },
    );
  }
}

class _GridHeader extends StatelessWidget {
  final ScrollController headerScrollController;
  const _GridHeader({required this.headerScrollController});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridBloc, GridState>(
      builder: (context, state) {
        return GridHeaderSliverAdaptor(
          viewId: state.viewId,
          fieldController:
              context.read<GridBloc>().databaseController.fieldController,
          anchorScrollController: headerScrollController,
        );
      },
    );
  }
}

class _GridRows extends StatelessWidget {
  final String viewId;
  final double contentWidth;
  final GridScrollController scrollController;

  const _GridRows({
    required this.viewId,
    required this.contentWidth,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: _WrapScrollView(
        scrollController: scrollController,
        contentWidth: contentWidth,
        child: BlocBuilder<GridBloc, GridState>(
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
              physics: const ClampingScrollPhysics(),
            );
            return ScrollConfiguration(
              behavior: behavior,
              child: _renderList(context, state, rowInfos),
            );
          },
        ),
      ),
    );
  }

  Widget _renderList(
    BuildContext context,
    GridState state,
    List<RowInfo> rowInfos,
  ) {
    final children = rowInfos.mapIndexed((index, rowInfo) {
      return ReorderableDelayedDragStartListener(
        key: ValueKey(rowInfo.rowMeta.id),
        index: index,
        child: _renderRow(
          context,
          rowInfo.rowId,
          isDraggable: state.reorderable,
          index: index,
        ),
      );
    }).toList();

    return ReorderableListView.builder(
      scrollController: scrollController.verticalController,
      buildDefaultDragHandles: false,
      proxyDecorator: (child, index, animation) => Material(
        color: Colors.transparent,
        child: child,
      ),
      onReorder: (fromIndex, newIndex) {
        final toIndex = newIndex > fromIndex ? newIndex - 1 : newIndex;
        if (fromIndex == toIndex) {
          return;
        }
        context.read<GridBloc>().add(GridEvent.moveRow(fromIndex, toIndex));
      },
      itemCount: rowInfos.length,
      itemBuilder: (context, index) => children[index],
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: GridSize.footerContentInsets,
            child: const SizedBox(
              height: 42,
              child: GridAddRowButton(
                key: Key('gridFooter'),
              ),
            ),
          ),
          Container(
            height: 30,
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: const _GridFooter(),
          ),
        ],
      ),
    );
  }

  Widget _renderRow(
    BuildContext context,
    RowId rowId, {
    int? index,
    required bool isDraggable,
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
      isDraggable: isDraggable,
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
        autoHideScrollbar: false,
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

class _GridFooter extends StatelessWidget {
  const _GridFooter();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<GridBloc, GridState, int>(
      selector: (state) => state.rowCount,
      builder: (context, rowCount) {
        return Padding(
          padding: GridSize.contentInsets,
          child: RichText(
            text: TextSpan(
              text: rowCountString(),
              style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
              children: [
                TextSpan(
                  text: ' $rowCount',
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        color: AFThemeExtension.of(context).gridRowCountColor,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String rowCountString() {
  return '${LocaleKeys.grid_row_count.tr()} :';
}
