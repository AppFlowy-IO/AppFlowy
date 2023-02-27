import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:appflowy/plugins/database_view/board/application/card/board_checkbox_cell_bloc.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardCheckboxCell extends StatefulWidget {
  final String groupId;
  final CellControllerBuilder cellControllerBuilder;

  const BoardCheckboxCell({
    required this.groupId,
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardCheckboxCell> createState() => _BoardCheckboxCellState();
}

class _BoardCheckboxCellState extends State<BoardCheckboxCell> {
  late BoardCheckboxCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as CheckboxCellController;
    _cellBloc = BoardCheckboxCellBloc(cellController: cellController);
    _cellBloc.add(const BoardCheckboxCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<BoardCheckboxCellBloc, BoardCheckboxCellState>(
        buildWhen: (previous, current) =>
            previous.isSelected != current.isSelected,
        builder: (context, state) {
          final icon = state.isSelected
              ? svgWidget('editor/editor_check')
              : svgWidget('editor/editor_uncheck');
          return Align(
            alignment: Alignment.centerLeft,
            child: FlowyIconButton(
              iconPadding: EdgeInsets.zero,
              icon: icon,
              width: 20,
              onPressed: () => context
                  .read<BoardCheckboxCellBloc>()
                  .add(const BoardCheckboxCellEvent.select()),
            ),
          );
        },
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }
}
