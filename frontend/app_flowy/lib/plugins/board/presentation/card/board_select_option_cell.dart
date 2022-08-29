import 'package:app_flowy/plugins/board/application/card/board_select_option_cell_bloc.dart';
import 'package:app_flowy/plugins/grid/application/cell/cell_service/cell_service.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/select_option_cell/extension.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/select_option_cell/select_option_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BoardSelectOptionCell extends StatefulWidget {
  final String groupId;
  final GridCellControllerBuilder cellControllerBuilder;

  const BoardSelectOptionCell({
    required this.groupId,
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  State<BoardSelectOptionCell> createState() => _BoardSelectOptionCellState();
}

class _BoardSelectOptionCellState extends State<BoardSelectOptionCell> {
  late BoardSelectOptionCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as GridSelectOptionCellController;
    _cellBloc = BoardSelectOptionCellBloc(cellController: cellController)
      ..add(const BoardSelectOptionCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<BoardSelectOptionCellBloc, BoardSelectOptionCellState>(
        buildWhen: (previous, current) {
          return previous.selectedOptions != current.selectedOptions;
        },
        builder: (context, state) {
          if (state.selectedOptions
                  .where((element) => element.id == widget.groupId)
                  .isNotEmpty ||
              state.selectedOptions.isEmpty) {
            return const SizedBox();
          } else {
            final children = state.selectedOptions
                .map(
                  (option) => SelectOptionTag.fromOption(
                    context: context,
                    option: option,
                  ),
                )
                .toList();

            return IntrinsicHeight(
              child: Stack(
                alignment: AlignmentDirectional.center,
                fit: StackFit.expand,
                children: [
                  Wrap(children: children, spacing: 4, runSpacing: 2),
                  _SelectOptionDialog(
                    controller: widget.cellControllerBuilder.build(),
                  ),
                ],
              ),
            );
          }
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

class _SelectOptionDialog extends StatelessWidget {
  final GridSelectOptionCellController _controller;
  const _SelectOptionDialog({
    Key? key,
    required IGridCellController controller,
  })  : _controller = controller as GridSelectOptionCellController,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: () {
      SelectOptionCellEditor.show(
        context,
        _controller,
        () {},
      );
    });
  }
}
