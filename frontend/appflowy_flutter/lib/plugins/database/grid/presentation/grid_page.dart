import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/calculations/calculations_row.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/toolbar/grid_setting_bar.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/setting_menu.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/workspace/application/notifications/notification_action.dart';
import 'package:appflowy/workspace/application/notifications/notification_action_bloc.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_scrollview.dart';
import 'package:flowy_infra_ui/widget/error_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

import '../../application/database_controller.dart';
import '../../application/row/row_cache.dart';
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
      child: BlocListener<NotificationActionBloc, NotificationActionState>(
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
              (_) => GridShortcuts(child: GridPageContent(view: widget.view)),
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
        builder: (_) => RowDetailPage(
          databaseController: context.read<GridBloc>().databaseController,
          rowController: rowController,
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
        _GridHeader(headerScrollController: headerScrollController),
        _GridRows(
          viewId: widget.view.id,
          scrollController: _scrollController,
        ),
        const _GridFooter(),
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

class _GridRows extends StatelessWidget {
  const _GridRows({
    required this.viewId,
    required this.scrollController,
  });

  final String viewId;
  final GridScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridBloc, GridState>(
      buildWhen: (previous, current) => previous.fields != current.fields,
      builder: (context, state) {
        return Flexible(
          child: _WrapScrollView(
            scrollController: scrollController,
            contentWidth: GridLayout.headerWidth(state.fields),
            child: BlocBuilder<GridBloc, GridState>(
              buildWhen: (previous, current) => current.reason.maybeWhen(
                reorderRows: () => true,
                reorderSingleRow: (reorderRow, rowInfo) => true,
                delete: (item) => true,
                insert: (item) => true,
                orElse: () => true,
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
      },
    );
  }

  Widget _renderList(
    BuildContext context,
    GridState state,
    List<RowInfo> rowInfos,
  ) {
    final children = rowInfos.mapIndexed((index, rowInfo) {
      return _renderRow(
        context,
        rowInfo.rowId,
        isDraggable: state.reorderable,
        index: index,
      );
    }).toList()
      ..add(const GridRowBottomBar(key: Key('grid_footer')))
      ..add(
        GridCalculationsRow(
          key: const Key('grid_calculations'),
          viewId: viewId,
        ),
      );

    return ReorderableListView.builder(
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
        if (fromIndex != toIndex) {
          context.read<GridBloc>().add(GridEvent.moveRow(fromIndex, toIndex));
        }
      },
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
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
      key: ValueKey(rowMeta.id),
      fieldController: databaseController.fieldController,
      rowId: rowId,
      viewId: viewId,
      index: index,
      isDraggable: isDraggable,
      rowController: rowController,
      cellBuilder: EditableCellBuilder(databaseController: databaseController),
      openDetailPage: (context, cellBuilder) {
        FlowyOverlay.show(
          context: context,
          builder: (BuildContext context) {
            return RowDetailPage(
              rowController: rowController,
              databaseController: databaseController,
            );
          },
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
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(color: Theme.of(context).hintColor),
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
