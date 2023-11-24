import 'dart:io';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HiddenGroupsColumn extends StatelessWidget {
  final EdgeInsets margin;
  const HiddenGroupsColumn({super.key, required this.margin});

  @override
  Widget build(BuildContext context) {
    final databaseController = context.read<BoardBloc>().databaseController;
    return BlocSelector<BoardBloc, BoardState, BoardLayoutSettingPB?>(
      selector: (state) => state.layoutSettings,
      builder: (context, layoutSettings) {
        if (layoutSettings == null) {
          return const SizedBox.shrink();
        }
        final isCollapsed = layoutSettings.collapseHiddenGroups;
        return AnimatedSize(
          alignment: AlignmentDirectional.topStart,
          curve: Curves.easeOut,
          duration: const Duration(milliseconds: 150),
          child: isCollapsed
              ? SizedBox(
                  height: 50,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 40, right: 8),
                    child: Center(
                      child: _collapseExpandIcon(context, isCollapsed),
                    ),
                  ),
                )
              : SizedBox(
                  width: 234,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 50,
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: 40 + margin.left,
                            right: margin.right + 4,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: FlowyText.medium(
                                  LocaleKeys
                                      .board_hiddenGroupSection_sectionTitle
                                      .tr(),
                                  overflow: TextOverflow.ellipsis,
                                  color: Theme.of(context).hintColor,
                                ),
                              ),
                              _collapseExpandIcon(context, isCollapsed),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: HiddenGroupList(
                          databaseController: databaseController,
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _collapseExpandIcon(BuildContext context, bool isCollapsed) {
    return FlowyTooltip(
      message: isCollapsed
          ? LocaleKeys.board_hiddenGroupSection_expandTooltip.tr()
          : LocaleKeys.board_hiddenGroupSection_collapseTooltip.tr(),
      preferBelow: false,
      child: FlowyIconButton(
        width: 20,
        height: 20,
        iconColorOnHover: Theme.of(context).colorScheme.onSurface,
        onPressed: () => context
            .read<BoardBloc>()
            .add(BoardEvent.toggleHiddenSectionVisibility(!isCollapsed)),
        icon: FlowySvg(
          isCollapsed
              ? FlowySvgs.hamburger_s_s
              : FlowySvgs.pull_left_outlined_s,
        ),
      ),
    );
  }
}

class HiddenGroupList extends StatelessWidget {
  const HiddenGroupList({
    super.key,
    required this.databaseController,
  });

  final DatabaseController databaseController;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BoardBloc>();
    return BlocBuilder<BoardBloc, BoardState>(
      builder: (_, state) => ReorderableListView.builder(
        proxyDecorator: (child, index, animation) => Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              child,
              MouseRegion(
                cursor: Platform.isWindows
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.grabbing,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
        buildDefaultDragHandles: false,
        itemCount: state.hiddenGroups.length,
        itemBuilder: (_, index) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          key: ValueKey("hiddenGroup${state.hiddenGroups[index].groupId}"),
          child: HiddenGroupCard(
            group: state.hiddenGroups[index],
            index: index,
            bloc: bloc,
          ),
        ),
        onReorder: (oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            newIndex--;
          }
          final fromGroupId = state.hiddenGroups[oldIndex].groupId;
          final toGroupId = state.hiddenGroups[newIndex].groupId;
          bloc.add(BoardEvent.reorderGroup(fromGroupId, toGroupId));
        },
      ),
    );
  }
}

class HiddenGroupCard extends StatefulWidget {
  const HiddenGroupCard({
    super.key,
    required this.group,
    required this.index,
    required this.bloc,
  });

  final GroupPB group;
  final BoardBloc bloc;
  final int index;

  @override
  State<HiddenGroupCard> createState() => _HiddenGroupCardState();
}

class _HiddenGroupCardState extends State<HiddenGroupCard> {
  final PopoverController _popoverController = PopoverController();

  @override
  Widget build(BuildContext context) {
    final databaseController = widget.bloc.databaseController;
    final primaryField = databaseController.fieldController.fieldInfos
        .firstWhereOrNull((element) => element.isPrimary)!;

    return Padding(
      padding: const EdgeInsets.only(left: 26),
      child: AppFlowyPopover(
        controller: _popoverController,
        direction: PopoverDirection.bottomWithCenterAligned,
        triggerActions: PopoverTriggerFlags.none,
        constraints: const BoxConstraints(maxWidth: 234, maxHeight: 300),
        popupBuilder: (popoverContext) => HiddenGroupPopupItemList(
          bloc: widget.bloc,
          viewId: databaseController.viewId,
          groupId: widget.group.groupId,
          primaryField: primaryField,
          rowCache: databaseController.rowCache,
        ),
        child: HiddenGroupButtonContent(
          popoverController: _popoverController,
          groupId: widget.group.groupId,
          index: widget.index,
          bloc: widget.bloc,
        ),
      ),
    );
  }
}

class HiddenGroupButtonContent extends StatelessWidget {
  final String groupId;
  final int index;
  final BoardBloc bloc;
  const HiddenGroupButtonContent({
    super.key,
    required this.popoverController,
    required this.groupId,
    required this.index,
    required this.bloc,
  });

  final PopoverController popoverController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: popoverController.show,
        child: FlowyHover(
          builder: (context, isHovering) {
            return BlocProvider<BoardBloc>.value(
              value: bloc,
              child: BlocBuilder<BoardBloc, BoardState>(
                builder: (context, state) {
                  final group = state.hiddenGroups.firstWhereOrNull(
                    (g) => g.groupId == groupId,
                  );
                  if (group == null) {
                    return const SizedBox.shrink();
                  }

                  return SizedBox(
                    height: 32,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 3,
                      ),
                      child: Row(
                        children: [
                          HiddenGroupCardActions(
                            isVisible: isHovering,
                            index: index,
                          ),
                          const HSpace(4),
                          FlowyText.medium(
                            group.groupName,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const HSpace(6),
                          Expanded(
                            child: FlowyText.medium(
                              group.rows.length.toString(),
                              overflow: TextOverflow.ellipsis,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          if (isHovering) ...[
                            FlowyIconButton(
                              width: 20,
                              icon: FlowySvg(
                                FlowySvgs.show_m,
                                color: Theme.of(context).hintColor,
                              ),
                              onPressed: () => context.read<BoardBloc>().add(
                                    BoardEvent.toggleGroupVisibility(
                                      group,
                                      true,
                                    ),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class HiddenGroupCardActions extends StatelessWidget {
  final bool isVisible;
  final int index;

  const HiddenGroupCardActions({
    super.key,
    required this.isVisible,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableDragStartListener(
      index: index,
      enabled: isVisible,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: SizedBox(
          height: 14,
          width: 14,
          child: isVisible
              ? FlowySvg(
                  FlowySvgs.drag_element_s,
                  color: Theme.of(context).hintColor,
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class HiddenGroupPopupItemList extends StatelessWidget {
  const HiddenGroupPopupItemList({
    required this.bloc,
    required this.groupId,
    required this.viewId,
    required this.primaryField,
    required this.rowCache,
    super.key,
  });

  final BoardBloc bloc;
  final String groupId;
  final String viewId;
  final FieldInfo primaryField;
  final RowCache rowCache;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<BoardBloc, BoardState>(
        builder: (context, state) {
          final group = state.hiddenGroups.firstWhereOrNull(
            (g) => g.groupId == groupId,
          );
          if (group == null) {
            return const SizedBox.shrink();
          }
          final cells = <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: FlowyText.medium(
                group.groupName,
                fontSize: 10,
                color: Theme.of(context).hintColor,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ...group.rows.map(
              (item) {
                final rowController = RowController(
                  rowMeta: item,
                  viewId: viewId,
                  rowCache: rowCache,
                );
                final renderHook = RowCardRenderHook<String>();
                renderHook.addTextCellHook((cellData, _, __) {
                  return BlocBuilder<TextCellBloc, TextCellState>(
                    builder: (context, state) {
                      final text = cellData.isEmpty
                          ? LocaleKeys.grid_row_titlePlaceholder.tr()
                          : cellData;

                      if (text.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FlowyText.medium(
                          text,
                          textAlign: TextAlign.left,
                          fontSize: 11,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  );
                });

                return HiddenGroupPopupItem(
                  cellContext: rowCache.loadCells(item)[primaryField.id]!,
                  primaryField: primaryField,
                  rowController: rowController,
                  cellBuilder: CardCellBuilder<String>(rowController.cellCache),
                  renderHook: renderHook,
                  onPressed: () {
                    FlowyOverlay.show(
                      context: context,
                      builder: (BuildContext context) {
                        return RowDetailPage(
                          fieldController:
                              context.read<BoardBloc>().fieldController,
                          cellBuilder: GridCellBuilder(
                            cellCache: rowController.cellCache,
                          ),
                          rowController: rowController,
                        );
                      },
                    );
                    PopoverContainer.of(context).close();
                  },
                );
              },
            ),
          ];

          return ListView.separated(
            itemBuilder: (context, index) => cells[index],
            itemCount: cells.length,
            separatorBuilder: (context, index) =>
                VSpace(GridSize.typeOptionSeparatorHeight),
            shrinkWrap: true,
          );
        },
      ),
    );
  }
}

class HiddenGroupPopupItem extends StatelessWidget {
  const HiddenGroupPopupItem({
    super.key,
    required this.cellContext,
    required this.onPressed,
    required this.cellBuilder,
    required this.rowController,
    required this.primaryField,
    required this.renderHook,
  });

  final DatabaseCellContext cellContext;
  final FieldInfo primaryField;
  final RowController rowController;
  final CardCellBuilder cellBuilder;
  final RowCardRenderHook<String> renderHook;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: FlowyButton(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        text: cellBuilder.buildCell(
          cellContext: cellContext,
          renderHook: renderHook,
          hasNotes: !cellContext.rowMeta.isDocumentEmpty,
        ),
        onTap: onPressed,
      ),
    );
  }
}
