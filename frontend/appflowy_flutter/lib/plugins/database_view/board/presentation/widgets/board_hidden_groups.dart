import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/database_controller.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database_view/board/application/hidden_group_button_bloc.dart';
import 'package:appflowy/plugins/database_view/board/application/hidden_groups_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/group.pb.dart';
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(48, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: FlowyText.medium(
                            LocaleKeys.board_hiddenGroupSection_sectionTitle
                                .tr(),
                            fontSize: 14,
                            overflow: TextOverflow.ellipsis,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        _collapseExpandIcon(),
                      ],
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
  }

  Widget _collapseExpandIcon() {
    return FlowyTooltip(
      message: isCollapsed
          ? LocaleKeys.board_hiddenGroupSection_expandTooltip.tr()
          : LocaleKeys.board_hiddenGroupSection_collapseTooltip.tr(),
      child: FlowyIconButton(
        width: 20,
        height: 20,
        iconColorOnHover: Theme.of(context).colorScheme.onSurface,
        onPressed: () => setState(() => isCollapsed = !isCollapsed),
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
    return BlocProvider<HiddenGroupsBloc>(
      create: (_) => HiddenGroupsBloc(
        databaseController: databaseController,
        initialGroups: context.read<BoardBloc>().groupList,
      )..add(const HiddenGroupsEvent.initial()),
      child: BlocBuilder<HiddenGroupsBloc, HiddenGroupsState>(
        builder: (_, state) => ListView.separated(
          itemCount: state.hiddenGroups.length,
          itemBuilder: (_, index) => HiddenGroupCard(
            group: state.hiddenGroups[index],
            key: ValueKey(state.hiddenGroups[index].groupId),
          ),
          separatorBuilder: (_, __) => const VSpace(4),
        ),
      ),
    );
  }
}

class HiddenGroupCard extends StatefulWidget {
  const HiddenGroupCard({super.key, required this.group});

  final GroupPB group;

  @override
  State<HiddenGroupCard> createState() => _HiddenGroupCardState();
}

class _HiddenGroupCardState extends State<HiddenGroupCard> {
  final PopoverController _popoverController = PopoverController();
  late final HiddenGroupButtonBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = HiddenGroupButtonBloc(group: widget.group)
      ..add(const HiddenGroupButtonEvent.initial());
  }

  @override
  Widget build(BuildContext context) {
    final databaseController = context.read<BoardBloc>().databaseController;
    final primaryField = databaseController.fieldController.fieldInfos
        .firstWhereOrNull((element) => element.isPrimary)!;

    return BlocProvider<HiddenGroupButtonBloc>.value(
      value: _bloc,
      child: Padding(
        padding: const EdgeInsets.only(left: 26),
        child: AppFlowyPopover(
          controller: _popoverController,
          direction: PopoverDirection.bottomWithCenterAligned,
          triggerActions: PopoverTriggerFlags.none,
          constraints: const BoxConstraints(maxWidth: 234, maxHeight: 300),
          popupBuilder: (popoverContext) => HiddenGroupPopupItemList(
            bloc: _bloc,
            viewId: databaseController.viewId,
            primaryField: primaryField,
            rowCache: databaseController.rowCache,
          ),
          child: HiddenGroupButtonContent(
            popoverController: _popoverController,
          ),
        ),
      ),
    );
  }
}

class HiddenGroupButtonContent extends StatelessWidget {
  const HiddenGroupButtonContent({
    super.key,
    required this.popoverController,
  });

  final PopoverController popoverController;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: popoverController.show,
      child: FlowyHover(
        builder: (context, isHovering) {
          return BlocBuilder<HiddenGroupButtonBloc, HiddenGroupButtonState>(
            builder: (context, state) {
              final group = state.hiddenGroup;

              return SizedBox(
                height: 30,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
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
                                BoardEvent.toggleGroupVisibility(group, true),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
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

class HiddenGroupPopupItemList extends StatelessWidget {
  const HiddenGroupPopupItemList({
    required this.bloc,
    required this.viewId,
    required this.primaryField,
    required this.rowCache,
    super.key,
  });

  final HiddenGroupButtonBloc bloc;
  final String viewId;
  final FieldInfo primaryField;
  final RowCache rowCache;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: bloc,
      child: BlocBuilder<HiddenGroupButtonBloc, HiddenGroupButtonState>(
        builder: (context, state) {
          final group = state.hiddenGroup;
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
            )
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
