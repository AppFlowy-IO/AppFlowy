import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/application/field/field_info.dart';
import 'package:appflowy/plugins/database_view/application/row/row_cache.dart';
import 'package:appflowy/plugins/database_view/application/row/row_controller.dart';
import 'package:appflowy/plugins/database_view/board/application/board_bloc.dart';
import 'package:appflowy/plugins/database_view/board/application/ungrouped_items_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/widgets/card/card_cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/card/cells/card_cell.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cell_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/text_cell/text_cell_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/row_detail.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/row_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UngroupedItemsButton extends StatefulWidget {
  const UngroupedItemsButton({super.key});

  @override
  State<UngroupedItemsButton> createState() => _UnscheduledEventsButtonState();
}

class _UnscheduledEventsButtonState extends State<UngroupedItemsButton> {
  late final PopoverController _popoverController;

  @override
  void initState() {
    super.initState();
    _popoverController = PopoverController();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BoardBloc, BoardState>(
      builder: (context, boardState) {
        final ungroupedGroup = context.watch<BoardBloc>().ungroupedGroup;
        final databaseController = context.read<BoardBloc>().databaseController;
        final primaryField = databaseController.fieldController.fieldInfos
            .firstWhereOrNull((element) => element.isPrimary)!;

        if (ungroupedGroup == null) {
          return const SizedBox.shrink();
        }

        return BlocProvider<UngroupedItemsBloc>(
          create: (_) => UngroupedItemsBloc(group: ungroupedGroup)
            ..add(const UngroupedItemsEvent.initial()),
          child: BlocBuilder<UngroupedItemsBloc, UngroupedItemsState>(
            builder: (context, state) {
              return AppFlowyPopover(
                direction: PopoverDirection.bottomWithCenterAligned,
                triggerActions: PopoverTriggerFlags.none,
                controller: _popoverController,
                offset: const Offset(0, 8),
                constraints:
                    const BoxConstraints(maxWidth: 282, maxHeight: 600),
                child: FlowyTooltip(
                  message: LocaleKeys.board_ungroupedButtonTooltip.tr(),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                        borderRadius: Corners.s6Border,
                      ),
                      side: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      if (state.ungroupedItems.isNotEmpty) {
                        _popoverController.show();
                      }
                    },
                    child: FlowyText.regular(
                      "${LocaleKeys.board_ungroupedButtonText.tr()} (${state.ungroupedItems.length})",
                      fontSize: 10,
                    ),
                  ),
                ),
                popupBuilder: (context) {
                  return UngroupedItemList(
                    viewId: databaseController.viewId,
                    primaryField: primaryField,
                    rowCache: databaseController.rowCache,
                    ungroupedItems: state.ungroupedItems,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class UngroupedItemList extends StatelessWidget {
  final String viewId;
  final FieldInfo primaryField;
  final RowCache rowCache;
  final List<RowMetaPB> ungroupedItems;
  const UngroupedItemList({
    required this.viewId,
    required this.primaryField,
    required this.ungroupedItems,
    required this.rowCache,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: FlowyText.medium(
          LocaleKeys.board_ungroupedItemsTitle.tr(),
          fontSize: 10,
          color: Theme.of(context).hintColor,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      ...ungroupedItems.map(
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
          return UngroupedItem(
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

class UngroupedItem extends StatelessWidget {
  final DatabaseCellContext cellContext;
  final FieldInfo primaryField;
  final RowController rowController;
  final CardCellBuilder cellBuilder;
  final RowCardRenderHook<String> renderHook;
  final VoidCallback onPressed;
  const UngroupedItem({
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
