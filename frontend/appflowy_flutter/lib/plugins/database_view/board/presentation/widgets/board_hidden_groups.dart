import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database_view/board/application/hidden_groups_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HiddenGroupsColumn extends StatefulWidget {
  const HiddenGroupsColumn({super.key});

  @override
  State<HiddenGroupsColumn> createState() => _HiddenGroupsColumnState();
}

class _HiddenGroupsColumnState extends State<HiddenGroupsColumn> {
  bool isCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final databaseController = context.read<BoardBloc>().databaseController;
    return AnimatedSize(
      alignment: AlignmentDirectional.topStart,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 150),
      child: isCollapsed
          ? Padding(
              padding: const EdgeInsets.fromLTRB(48, 16, 8, 8),
              child: _collapseExpandIcon(),
            )
          : SizedBox(
              width: 260,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: FlowyText.medium(
                            'Hidden groups',
                            fontSize: 14,
                            overflow: TextOverflow.ellipsis,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        _collapseExpandIcon(),
                      ],
                    ),
                  ),
                  // cards
                  Expanded(
                    child:
                        HiddenGroupList(databaseController: databaseController),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _collapseExpandIcon() {
    return FlowyTooltip(
      message: isCollapsed ? "Expand group" : "Collpase group",
      child: FlowyIconButton(
        width: 20,
        height: 20,
        icon: FlowySvg(
          isCollapsed
              ? FlowySvgs.hamburger_s_s
              : FlowySvgs.pull_left_outlined_s,
        ),
        iconColorOnHover: Theme.of(context).colorScheme.onSurface,
        onPressed: () => setState(() {
          isCollapsed = !isCollapsed;
        }),
      ),
    );
  }
}

class HiddenGroupList extends StatelessWidget {
  final DatabaseController databaseController;
  const HiddenGroupList({super.key, required this.databaseController});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HiddenGroupsBloc(
        databaseController: databaseController,
        initialHiddenGroups: context.read<BoardBloc>().hiddenGroups,
      )..add(const HiddenGroupsEvent.initial()),
      child: BlocBuilder<HiddenGroupsBloc, HiddenGroupsState>(
        builder: (context, state) {
          return ListView.separated(
            itemCount: state.hiddenGroups.length,
            itemBuilder: (context, index) => HiddenGroupCard(
              group: state.hiddenGroups[index],
            ),
            separatorBuilder: (context, index) => const VSpace(4),
          );
        },
      ),
    );
  }
}

class HiddenGroupCard extends StatefulWidget {
  final GroupPB group;
  const HiddenGroupCard({super.key, required this.group});

  @override
  State<HiddenGroupCard> createState() => _HiddenGroupCardState();
}

class _HiddenGroupCardState extends State<HiddenGroupCard> {
  late final PopoverController _popoverController;

  @override
  void initState() {
    super.initState();
    _popoverController = PopoverController();
  }

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _popoverController.show(),
      child: FlowyHover(
        resetHoverOnRebuild: false,
        builder: (context, isHovering) {
          return SizedBox(
            height: 30,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Opacity(
                    opacity: isHovering ? 1 : 0,
                    child: const HiddenGroupCardActions(),
                  ),
                  const HSpace(4),
                  FlowyText.medium(
                    widget.group.groupName,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const HSpace(6),
                  Expanded(
                    child: FlowyText.medium(
                      widget.group.rows.length.toString(),
                      overflow: TextOverflow.ellipsis,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  FlowyIconButton(
                    width: 20,
                    icon: isHovering
                        ? FlowySvg(
                            FlowySvgs.show_m,
                            color: Theme.of(context).hintColor,
                          )
                        : const SizedBox.shrink(),
                    onPressed: () {
                      context.read<BoardBloc>().add(
                            BoardEvent.toggleGroupVisibility(
                              widget.group.groupId,
                              true,
                            ),
                          );
                    },
                  )
                ],
              ),
            ),
          );
        },
      ),
    );

    final databaseController = context.read<BoardBloc>().databaseController;
    final primaryField = databaseController.fieldController.fieldInfos
        .firstWhereOrNull((element) => element.isPrimary)!;
    return Padding(
      padding: const EdgeInsets.only(left: 26),
      child: _wrapPopover(
        button,
        databaseController,
        widget.group.rows,
        primaryField,
        widget.group.groupName,
      ),
    );
  }

  Widget _wrapPopover(
    Widget child,
    DatabaseController databaseController,
    List<RowMetaPB> items,
    FieldInfo primaryField,
    String groupName,
  ) {
    return AppFlowyPopover(
      controller: _popoverController,
      direction: PopoverDirection.bottomWithCenterAligned,
      triggerActions: PopoverTriggerFlags.none,
      constraints: const BoxConstraints(maxWidth: 234),
      popupBuilder: (popoverContext) {
        return HiddenGroupPopupItemList(
          name: groupName,
          viewId: databaseController.viewId,
          primaryField: primaryField,
          groupItems: items,
          rowCache: databaseController.rowCache,
        );
      },
      child: child,
    );
  }
}

class HiddenGroupCardActions extends StatelessWidget {
  const HiddenGroupCardActions({super.key});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      width: 14,
      child: FlowySvg(
        FlowySvgs.drag_element_s,
        color: Theme.of(context).hintColor,
      ),
    );
  }
}

class HiddenGroupPopover extends StatelessWidget {
  const HiddenGroupPopover({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 234, height: 100);
  }
}

class HiddenGroupPopupItemList extends StatelessWidget {
  final String name;
  final String viewId;
  final FieldInfo primaryField;
  final RowCache rowCache;
  final List<RowMetaPB> groupItems;
  const HiddenGroupPopupItemList({
    required this.viewId,
    required this.primaryField,
    required this.groupItems,
    required this.rowCache,
    required this.name,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: FlowyText.medium(
          name,
          fontSize: 10,
          color: Theme.of(context).hintColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      ...groupItems.map(
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
                    cellBuilder:
                        GridCellBuilder(cellCache: rowController.cellCache),
                    rowController: rowController,
                  );
                },
              );
              PopoverContainer.of(context).close();
            },
          );
        },
      )
    ];

    return ListView.separated(
      itemBuilder: (context, index) => cells[index],
      itemCount: cells.length,
      separatorBuilder: (context, index) =>
          VSpace(GridSize.typeOptionSeparatorHeight),
      shrinkWrap: true,
    );
  }
}

class HiddenGroupPopupItem extends StatelessWidget {
  final DatabaseCellContext cellContext;
  final FieldInfo primaryField;
  final RowController rowController;
  final CardCellBuilder cellBuilder;
  final RowCardRenderHook<String> renderHook;
  final VoidCallback onPressed;
  const HiddenGroupPopupItem({
    super.key,
    required this.cellContext,
    required this.onPressed,
    required this.cellBuilder,
    required this.rowController,
    required this.primaryField,
    required this.renderHook,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      child: FlowyButton(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        text: cellBuilder.buildCell(
          cellContext: cellContext,
          renderHook: renderHook,
        ),
        onTap: onPressed,
      ),
    );
  }
}
