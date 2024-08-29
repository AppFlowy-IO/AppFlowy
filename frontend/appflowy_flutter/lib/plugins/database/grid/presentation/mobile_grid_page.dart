import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/mobile_card_detail_screen.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/application/grid_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/shortcuts.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/workspace/application/action_navigation/action_navigation_bloc.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

import 'grid_scroll.dart';
import 'layout/sizes.dart';
import 'widgets/header/mobile_grid_header.dart';
import 'widgets/mobile_fab.dart';
import 'widgets/row/mobile_row.dart';

class MobileGridTabBarBuilderImpl extends DatabaseTabBarItemBuilder {
  @override
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
    bool shrinkWrap,
    String? initialRowId,
  ) {
    return MobileGridPage(
      key: _makeValueKey(controller),
      view: view,
      databaseController: controller,
      initialRowId: initialRowId,
    );
  }

  @override
  Widget settingBar(BuildContext context, DatabaseController controller) =>
      const SizedBox.shrink();

  @override
  Widget settingBarExtension(
    BuildContext context,
    DatabaseController controller,
  ) =>
      const SizedBox.shrink();

  ValueKey _makeValueKey(DatabaseController controller) {
    return ValueKey(controller.viewId);
  }
}

class MobileGridPage extends StatefulWidget {
  const MobileGridPage({
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
  State<MobileGridPage> createState() => _MobileGridPageState();
}

class _MobileGridPageState extends State<MobileGridPage> {
  bool _didOpenInitialRow = false;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ActionNavigationBloc>.value(
          value: getIt<ActionNavigationBloc>(),
        ),
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
            finish: (result) {
              _openRow(context, widget.initialRowId, true);
              return result.successOrFail.fold(
                (_) => GridShortcuts(child: GridPageContent(view: widget.view)),
                (err) => AppFlowyErrorPage(
                  error: err,
                ),
              );
            },
            idle: (_) => const SizedBox.shrink(),
          );
        },
      ),
    );
  }

  void _openRow(
    BuildContext context,
    String? rowId, [
    bool initialRow = false,
  ]) {
    if (rowId != null && (!initialRow || (initialRow && !_didOpenInitialRow))) {
      _didOpenInitialRow = initialRow;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.push(
          MobileRowDetailPage.routeName,
          extra: {
            MobileRowDetailPage.argRowId: rowId,
            MobileRowDetailPage.argDatabaseController:
                widget.databaseController,
          },
        );
      });
    }
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
  late final ScrollController contentScrollController;
  late final ScrollController reorderableController;

  @override
  void initState() {
    super.initState();
    contentScrollController = _scrollController.linkHorizontalController();
    reorderableController = _scrollController.linkHorizontalController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GridBloc, GridState>(
      listenWhen: (previous, current) =>
          previous.createdRow != current.createdRow,
      listener: (context, state) {
        if (state.createdRow == null || !state.openRowDetail) {
          return;
        }
        final bloc = context.read<GridBloc>();
        context.push(
          MobileRowDetailPage.routeName,
          extra: {
            MobileRowDetailPage.argRowId: state.createdRow!.id,
            MobileRowDetailPage.argDatabaseController: bloc.databaseController,
          },
        );
        bloc.add(const GridEvent.resetCreatedRow());
      },
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GridHeader(
                contentScrollController: contentScrollController,
                reorderableController: reorderableController,
              ),
              _GridRows(
                viewId: widget.view.id,
                scrollController: _scrollController,
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: getGridFabs(context),
          ),
        ],
      ),
    );
  }
}

class _GridHeader extends StatelessWidget {
  const _GridHeader({
    required this.contentScrollController,
    required this.reorderableController,
  });

  final ScrollController contentScrollController;
  final ScrollController reorderableController;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GridBloc, GridState>(
      builder: (context, state) {
        return MobileGridHeader(
          viewId: state.viewId,
          contentScrollController: contentScrollController,
          reorderableController: reorderableController,
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
        final double contentWidth = getMobileGridContentWidth(state.fields);
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
                final behavior = ScrollConfiguration.of(context).copyWith(
                  scrollbars: false,
                  physics: const ClampingScrollPhysics(),
                );
                return ScrollConfiguration(
                  behavior: behavior,
                  child: _renderList(context, state),
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
  ) {
    final children = state.rowInfos.mapIndexed((index, rowInfo) {
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
      itemCount: state.rowInfos.length,
      itemBuilder: (context, index) => children[index],
      footer: Padding(
        padding: GridSize.footerContentInsets,
        child: _AddRowButton(),
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
    final rowMeta = context
        .read<GridBloc>()
        .databaseController
        .rowCache
        .getRow(rowId)
        ?.rowMeta;

    if (rowMeta == null) {
      Log.warn('RowMeta is null for rowId: $rowId');
      return const SizedBox.shrink();
    }

    final databaseController = context.read<GridBloc>().databaseController;

    final child = MobileGridRow(
      key: ValueKey(rowMeta.id),
      rowId: rowId,
      isDraggable: isDraggable,
      databaseController: databaseController,
      openDetailPage: (context) {
        context.push(
          MobileRowDetailPage.routeName,
          extra: {
            MobileRowDetailPage.argRowId: rowId,
            MobileRowDetailPage.argDatabaseController: databaseController,
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
    return SingleChildScrollView(
      controller: scrollController.horizontalController,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: contentWidth,
        child: child,
      ),
    );
  }
}

class _AddRowButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final borderSide = BorderSide(
      color: Theme.of(context).dividerColor,
    );
    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(24),
      bottomRight: Radius.circular(24),
    );
    final decoration = BoxDecoration(
      borderRadius: radius,
      border: BorderDirectional(
        start: borderSide,
        end: borderSide,
        bottom: borderSide,
      ),
    );
    return Container(
      height: 54,
      decoration: decoration,
      child: FlowyButton(
        text: FlowyText(
          LocaleKeys.grid_row_newRow.tr(),
          fontSize: 15,
          color: Theme.of(context).hintColor,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20.0),
        radius: radius,
        hoverColor: AFThemeExtension.of(context).lightGreyHover,
        onTap: () => context.read<GridBloc>().add(const GridEvent.createRow()),
        leftIcon: FlowySvg(
          FlowySvgs.add_s,
          color: Theme.of(context).hintColor,
          size: const Size.square(18),
        ),
        leftIconSize: const Size.square(18),
      ),
    );
  }
}

double getMobileGridContentWidth(List<FieldInfo> fields) {
  final visibleFields = fields.where(
    (field) => field.visibility != FieldVisibility.AlwaysHidden,
  );
  return (visibleFields.length + 1) * 200 +
      GridSize.horizontalHeaderPadding * 2;
}
