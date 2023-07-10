import 'dart:io';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/row/row_service.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/toolbar/grid_setting_bar.dart';
import 'package:appflowy/plugins/database_view/tar_bar/setting_menu.dart';
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
import '../application/grid_bloc.dart';
import '../../application/database_controller.dart';
import 'grid_scroll.dart';
import '../../tar_bar/tab_bar_view.dart';
import 'layout/layout.dart';
import 'layout/sizes.dart';
import 'widgets/row/row.dart';
import 'widgets/footer/grid_footer.dart';
import 'widgets/header/grid_header.dart';
import '../../widgets/row/row_detail.dart';
import 'widgets/shortcuts.dart';

class ToggleExtensionNotifier extends ChangeNotifier {
  bool _isToggled = false;

  get isToggled => _isToggled;

  void toggle() {
    _isToggled = !_isToggled;
    notifyListeners();
  }
}

class GridPageTabBarBuilderImpl implements DatabaseTabBarItemBuilder {
  final _toggleExtension = ToggleExtensionNotifier();

  @override
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
  ) {
    return GridPage(
      key: _makeValueKey(controller),
      view: view,
      databaseController: controller,
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

  ValueKey _makeValueKey(DatabaseController controller) {
    return ValueKey(controller.viewId);
  }
}

class GridPage extends StatefulWidget {
  final DatabaseController databaseController;
  const GridPage({
    required this.view,
    required this.databaseController,
    this.onDeleted,
    Key? key,
  }) : super(key: key);

  final ViewPB view;
  final VoidCallback? onDeleted;

  @override
  State<GridPage> createState() => _GridPageState();
}

class _GridPageState extends State<GridPage> {
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
        final contentWidth = GridLayout.headerWidth(state.fields.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GridHeader(headerScrollController: headerScrollController),
            _GridRows(
              viewId: state.viewId,
              contentWidth: contentWidth,
              scrollController: _scrollController,
            ),
            const _GridFooter(),
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
    return Flexible(
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
    if (Platform.isWindows) {
      // Workaround: On Windows, the focusing of the text cell is not working
      // properly when the list is reorderable. So using the ListView instead.
      return ListView.builder(
        controller: scrollController.verticalController,
        itemCount: rowInfos.length + 1, // the extra item is the footer
        itemBuilder: (context, index) {
          if (index < rowInfos.length) {
            final rowInfo = rowInfos[index];
            return _renderRow(
              context,
              rowInfo.rowId,
              isDraggable: false,
              index: index,
            );
          }
          return const GridRowBottomBar(key: Key('gridFooter'));
        },
      );
    } else {
      return ReorderableListView.builder(
        /// TODO(Xazin): Resolve inconsistent scrollbar behavior
        ///  This is a workaround related to
        ///  https://github.com/flutter/flutter/issues/25652
        cacheExtent: 5000,
        scrollController: scrollController.verticalController,
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
          context.read<GridBloc>().add(GridEvent.moveRow(fromIndex, toIndex));
        },
        itemCount: rowInfos.length + 1, // the extra item is the footer
        itemBuilder: (context, index) {
          if (index < rowInfos.length) {
            final rowInfo = rowInfos[index];
            return _renderRow(
              context,
              rowInfo.rowId,
              isDraggable: state.reorderable,
              index: index,
            );
          }
          return const GridRowBottomBar(key: Key('gridFooter'));
        },
      );
    }
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
