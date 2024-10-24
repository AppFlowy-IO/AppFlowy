import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/row/row_controller.dart';
import 'package:appflowy/plugins/database/gallery/application/gallery_bloc.dart';
import 'package:appflowy/plugins/database/gallery/presentation/gallery_card.dart';
import 'package:appflowy/plugins/database/gallery/presentation/toolbar/gallery_toolbar.dart';
import 'package:appflowy/plugins/database/grid/presentation/grid_page.dart';
import 'package:appflowy/plugins/database/tab_bar/desktop/setting_menu.dart';
import 'package:appflowy/plugins/database/tab_bar/tab_bar_view.dart';
import 'package:appflowy/plugins/database/widgets/card/card.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/cell/card_cell_style_maps/desktop_board_card_cell_style.dart';
import 'package:appflowy/plugins/database/widgets/row/row_detail.dart';
import 'package:appflowy/shared/flowy_error_page.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reorderables/reorderables.dart';

const double _minItemWidth = 200;
const double _maxItemWidth = 350;

class GalleryPageTabBarBuilderImpl extends DatabaseTabBarItemBuilder {
  final _toggleExtension = ToggleExtensionNotifier();

  @override
  Widget content(
    BuildContext context,
    ViewPB view,
    DatabaseController controller,
    bool shrinkWrap,
    String? initialRowId,
  ) {
    return GalleryPage(
      key: _makeValueKey(controller),
      view: view,
      databaseController: controller,
    );
  }

  @override
  Widget settingBar(BuildContext context, DatabaseController controller) {
    return GalleryToolbar(
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

  ValueKey _makeValueKey(DatabaseController controller) =>
      ValueKey(controller.viewId);
}

class GalleryPage extends StatelessWidget {
  const GalleryPage({
    super.key,
    required this.view,
    required this.databaseController,
  });

  final ViewPB view;
  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GalleryBloc>(
      create: (_) => GalleryBloc(
        view: view,
        databaseController: databaseController,
      )..add(const GalleryEvent.initial()),
      child: BlocBuilder<GalleryBloc, GalleryState>(
        builder: (context, state) => state.loadingState.map(
          loading: (_) => const Center(child: CircularProgressIndicator()),
          finish: (result) => result.successOrFail.fold(
            (_) => GalleryContent(
              key: ValueKey(view.id),
              viewId: view.id,
              controller: databaseController,
              cellBuilder: CardCellBuilder(
                databaseController: databaseController,
              ),
            ),
            (err) => Center(child: AppFlowyErrorPage(error: err)),
          ),
          idle: (_) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class GalleryContent extends StatefulWidget {
  const GalleryContent({
    super.key,
    required this.viewId,
    required this.controller,
    required this.cellBuilder,
  });

  final String viewId;
  final DatabaseController controller;
  final CardCellBuilder cellBuilder;

  @override
  State<GalleryContent> createState() => _GalleryContentState();
}

class _GalleryContentState extends State<GalleryContent> {
  bool isReordering = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GalleryBloc, GalleryState>(
      builder: (context, state) {
        return Padding(
          padding: EdgeInsets.symmetric(
            vertical: 8,
            horizontal: context
                .read<DatabasePluginWidgetBuilderSize>()
                .horizontalPadding,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;

              const double spacing = 8;

              final maxItemsPerRow = calculateItemsPerRow(maxWidth, spacing);

              final itemCount = state.rowCount + 1;
              final itemsPerRow =
                  itemCount < maxItemsPerRow ? itemCount : maxItemsPerRow;

              // Calculate the width of each item in the current row configuration
              // Without the 0.0...1 buffer, resizing can cause odd behavior
              final totalSpacing = (itemsPerRow - 1) * spacing + 0.000001;
              double itemWidth = (maxWidth - totalSpacing) / itemsPerRow;
              itemWidth = itemWidth.isFinite ? itemWidth : double.infinity;

              return ReorderableWrap(
                enableReorder: state.sorts.isEmpty,
                spacing: spacing,
                runSpacing: spacing,
                onReorder: (oldIndex, newIndex) {
                  if (oldIndex != newIndex && newIndex < itemCount - 1) {
                    context
                        .read<GalleryBloc>()
                        .add(GalleryEvent.moveRow(oldIndex, newIndex));
                  }
                  setState(() => isReordering = false);
                },
                onReorderStarted: (_) => setState(() => isReordering = true),
                onNoReorder: (_) => setState(() => isReordering = false),
                buildDraggableFeedback: (_, __, child) => Material(
                  type: MaterialType.transparency,
                  child: Opacity(opacity: 0.8, child: child),
                ),
                footer: _AddCard(
                  itemWidth: itemWidth,
                  disableHover: isReordering,
                ),
                children: state.rowInfos.map<Widget>((rowInfo) {
                  return SizedBox(
                    key: ValueKey(rowInfo.rowId),
                    width: itemWidth,
                    child: GalleryCard(
                      controller: widget.controller.fieldController,
                      userProfile: context.read<GalleryBloc>().userProfile,
                      cellBuilder: widget.cellBuilder,
                      rowMeta: rowInfo.rowMeta,
                      viewId: widget.viewId,
                      rowCache: widget.controller.rowCache,
                      styleConfiguration: RowCardStyleConfiguration(
                        cellStyleMap: desktopBoardCardCellStyleMap(context),
                      ),
                      onTap: (_) => _openCard(
                        context: context,
                        databaseController: widget.controller,
                        rowMeta: rowInfo.rowMeta,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      },
    );
  }

  void _openCard({
    required BuildContext context,
    required DatabaseController databaseController,
    required RowMetaPB rowMeta,
  }) {
    final rowController = RowController(
      rowMeta: rowMeta,
      viewId: databaseController.viewId,
      rowCache: databaseController.rowCache,
    );

    FlowyOverlay.show(
      context: context,
      builder: (_) => RowDetailPage(
        databaseController: databaseController,
        rowController: rowController,
        userProfile: context.read<GalleryBloc>().userProfile,
      ),
    );
  }

  int calculateItemsPerRow(
    double maxWidth,
    double spacing,
  ) {
    int itemsPerRow = (maxWidth / (_minItemWidth + spacing)).floor();

    while (itemsPerRow > 1 &&
        ((maxWidth - (itemsPerRow - 1) * spacing) / itemsPerRow) >
            _maxItemWidth) {
      itemsPerRow--;
    }

    return itemsPerRow;
  }
}

class _AddCard extends StatelessWidget {
  const _AddCard({
    required this.itemWidth,
    this.disableHover = false,
  });

  final double itemWidth;
  final bool disableHover;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () =>
          context.read<GalleryBloc>().add(const GalleryEvent.createRow()),
      child: FlowyHover(
        resetHoverOnRebuild: false,
        buildWhenOnHover: () => !disableHover,
        builder: (context, isHovering) => SizedBox(
          width: itemWidth,
          height: itemWidth == double.infinity ? 175 : 140,
          child: DottedBorder(
            dashPattern: const [3, 3],
            radius: const Radius.circular(8),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 32,
            ),
            borderType: BorderType.RRect,
            color: isHovering && !disableHover
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).hintColor,
            child: Center(
              child: FlowyText(
                LocaleKeys.databaseGallery_addCard.tr(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
