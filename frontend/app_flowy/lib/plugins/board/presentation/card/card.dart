import 'package:app_flowy/plugins/board/application/card/card_bloc.dart';
import 'package:app_flowy/plugins/board/application/card/card_data_controller.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/row/row_action_sheet.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  void initState() {
    _cardBloc = BoardCardBloc(
      gridId: widget.gridId,
      fieldId: widget.fieldId,
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
          return previous.cells.length != current.cells.length;
        },
        builder: (context, state) {
          return BoardCardContainer(
            accessoryBuilder: (context) {
              return [const _CardMoreOption()];
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
    cells.asMap().forEach(
      (int index, GridCellIdentifier cellId) {
        Widget child = widget.cellBuilder.buildCell(
          widget.groupId,
          cellId,
          widget.isEditing,
        );

        if (index != 0) {
          child = Padding(
            key: cellId.key(),
            padding: const EdgeInsets.only(left: 4, right: 4, top: 8),
            child: child,
          );
        } else {
          child = Padding(
            key: UniqueKey(),
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: child,
          );
        }

        children.add(child);
      },
    );
    return children;
  }

  @override
  Future<void> dispose() async {
    _cardBloc.close();
    super.dispose();
  }
}

class _CardMoreOption extends StatelessWidget with CardAccessory {
  const _CardMoreOption({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return svgWidget('grid/details', color: context.read<AppTheme>().iconColor);
  }

  @override
  void onTap(BuildContext context) {
    GridRowActionSheet(
      rowData: context.read<BoardCardBloc>().rowInfo(),
    ).show(context, direction: AnchorDirection.bottomWithCenterAligned);
  }
}
