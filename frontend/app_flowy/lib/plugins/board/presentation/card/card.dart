import 'package:app_flowy/plugins/board/application/card/card_bloc.dart';
import 'package:app_flowy/plugins/board/application/card/card_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/row/row_action_sheet.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'board_cell.dart';
import 'card_cell_builder.dart';
import 'card_container.dart';

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

  @override
  void initState() {
    rowNotifier = EditableRowNotifier();
    _cardBloc = BoardCardBloc(
      gridId: widget.gridId,
      groupFieldId: widget.fieldId,
      dataController: widget.dataController,
    )..add(const BoardCardEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cardBloc,
      child: BlocBuilder<BoardCardBloc, BoardCardState>(
        buildWhen: (previous, current) {
          if (previous.cells.length != current.cells.length) {
            return true;
          }
          return !listEquals(previous.cells, current.cells);
        },
        builder: (context, state) {
          return BoardCardContainer(
            accessoryBuilder: (context) {
              return [
                _CardEditOption(
                  startEditing: () => rowNotifier.becomeFirstResponder(),
                ),
                const _CardMoreOption(),
              ];
            },
            onTap: (context) {
              widget.openCard(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _makeCells(
                context,
                state.cells.map((cell) => cell.identifier).toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _makeCells(
    BuildContext context,
    List<GridCellIdentifier> cells,
  ) {
    final List<Widget> children = [];
    rowNotifier.clear();
    cells.asMap().forEach(
      (int index, GridCellIdentifier cellId) {
        final cellNotifier = EditableCellNotifier();
        Widget child = widget.cellBuilder.buildCell(
          widget.groupId,
          cellId,
          index == 0 ? widget.isEditing : false,
          cellNotifier,
        );

        if (index == 0) {
          rowNotifier.insertCell(cellId, cellNotifier);
        }
        child = Padding(
          key: cellId.key(),
          padding: const EdgeInsets.only(left: 4, right: 4),
          child: child,
        );

        children.add(child);
      },
    );
    return children;
  }

  @override
  Future<void> dispose() async {
    rowNotifier.dispose();
    _cardBloc.close();
    super.dispose();
  }
}

class _CardMoreOption extends StatelessWidget with CardAccessory {
  const _CardMoreOption({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child:
          svgWidget('grid/details', color: context.read<AppTheme>().iconColor),
    );
  }

  @override
  void onTap(BuildContext context) {
    GridRowActionSheet(
      rowData: context.read<BoardCardBloc>().rowInfo(),
    ).show(context, direction: AnchorDirection.bottomWithCenterAligned);
  }
}

class _CardEditOption extends StatelessWidget with CardAccessory {
  final VoidCallback startEditing;
  const _CardEditOption({
    required this.startEditing,
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
  void onTap(BuildContext context) {
    startEditing();
  }
}
