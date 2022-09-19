import 'package:app_flowy/plugins/board/application/card/card_bloc.dart';
import 'package:app_flowy/plugins/board/application/card/card_data_controller.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/row/row_action_sheet.dart';
import 'package:appflowy_popover/popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'board_cell.dart';
import 'card_cell_builder.dart';
import 'container/accessory.dart';
import 'container/card_container.dart';

class BoardCard extends StatefulWidget {
  final String gridId;
  final String groupId;
  final String fieldId;
  final bool isEditing;
  final CardDataController dataController;
  final BoardCellBuilder cellBuilder;
  final void Function(BuildContext) openCard;

  const BoardCard({
    required this.gridId,
    required this.groupId,
    required this.fieldId,
    required this.isEditing,
    required this.dataController,
    required this.cellBuilder,
    required this.openCard,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardCard> createState() => _BoardCardState();
}

class _BoardCardState extends State<BoardCard> {
  late BoardCardBloc _cardBloc;
  late EditableRowNotifier rowNotifier;
  late PopoverController popoverController;
  AccessoryType? accessoryType;

  @override
  void initState() {
    rowNotifier = EditableRowNotifier(isEditing: widget.isEditing);
    _cardBloc = BoardCardBloc(
      gridId: widget.gridId,
      groupFieldId: widget.fieldId,
      dataController: widget.dataController,
      isEditing: widget.isEditing,
    )..add(const BoardCardEvent.initial());

    rowNotifier.isEditing.addListener(() {
      if (!mounted) return;
      _cardBloc.add(BoardCardEvent.setIsEditing(rowNotifier.isEditing.value));
    });

    popoverController = PopoverController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cardBloc,
      child: BlocBuilder<BoardCardBloc, BoardCardState>(
        buildWhen: (previous, current) {
          // Rebuild when:
          // 1.If the length of the cells is not the same
          // 2.isEditing changed
          if (previous.cells.length != current.cells.length ||
              previous.isEditing != current.isEditing) {
            return true;
          }

          // 3.Compare the content of the cells. The cells consists of
          // list of [BoardCellEquatable] that extends the [Equatable].
          return !listEquals(previous.cells, current.cells);
        },
        builder: (context, state) {
          return AppFlowyPopover(
            controller: popoverController,
            constraints: BoxConstraints.loose(const Size(140, 200)),
            direction: PopoverDirection.rightWithCenterAligned,
            popupBuilder: (popoverContext) => _handlePopoverBuilder(
              context,
              popoverContext,
            ),
            child: BoardCardContainer(
              buildAccessoryWhen: () => state.isEditing == false,
              accessoryBuilder: (context) {
                return [
                  _CardEditOption(rowNotifier: rowNotifier),
                  _CardMoreOption(),
                ];
              },
              openAccessory: _handleOpenAccessory,
              openCard: (context) => widget.openCard(context),
              child: _CellColumn(
                groupId: widget.groupId,
                rowNotifier: rowNotifier,
                cellBuilder: widget.cellBuilder,
                cells: state.cells,
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleOpenAccessory(AccessoryType newAccessoryType) {
    accessoryType = newAccessoryType;
    switch (newAccessoryType) {
      case AccessoryType.edit:
        break;
      case AccessoryType.more:
        popoverController.show();
        break;
    }
  }

  Widget _handlePopoverBuilder(
    BuildContext context,
    BuildContext popoverContext,
  ) {
    switch (accessoryType!) {
      case AccessoryType.edit:
        throw UnimplementedError();
      case AccessoryType.more:
        return GridRowActionSheet(
            rowData: context.read<BoardCardBloc>().rowInfo());
    }
  }

  @override
  Future<void> dispose() async {
    rowNotifier.dispose();
    _cardBloc.close();
    super.dispose();
  }
}

class _CellColumn extends StatelessWidget {
  final String groupId;
  final BoardCellBuilder cellBuilder;
  final EditableRowNotifier rowNotifier;
  final List<BoardCellEquatable> cells;
  const _CellColumn({
    required this.groupId,
    required this.rowNotifier,
    required this.cellBuilder,
    required this.cells,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _makeCells(context, cells),
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    List<BoardCellEquatable> cells,
  ) {
    final List<Widget> children = [];
    // Remove all the cell listeners.
    rowNotifier.unbind();

    cells.asMap().forEach(
      (int index, BoardCellEquatable cell) {
        final isEditing = index == 0 ? rowNotifier.isEditing.value : false;
        final cellNotifier = EditableCellNotifier(isEditing: isEditing);

        if (index == 0) {
          // Only use the first cell to receive user's input when click the edit
          // button
          rowNotifier.bindCell(cell.identifier, cellNotifier);
        }

        final child = Padding(
          key: cell.identifier.key(),
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: cellBuilder.buildCell(
            groupId,
            cell.identifier,
            cellNotifier,
          ),
        );

        children.add(child);
      },
    );
    return children;
  }
}

class _CardMoreOption extends StatelessWidget with CardAccessory {
  _CardMoreOption({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child:
          svgWidget('grid/details', color: context.read<AppTheme>().iconColor),
    );
  }

  @override
  AccessoryType get type => AccessoryType.more;
}

class _CardEditOption extends StatelessWidget with CardAccessory {
  final EditableRowNotifier rowNotifier;
  const _CardEditOption({
    required this.rowNotifier,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: svgWidget(
        'editor/edit',
        color: context.read<AppTheme>().iconColor,
      ),
    );
  }

  @override
  void onTap(BuildContext context) => rowNotifier.becomeFirstResponder();

  @override
  AccessoryType get type => AccessoryType.edit;
}
