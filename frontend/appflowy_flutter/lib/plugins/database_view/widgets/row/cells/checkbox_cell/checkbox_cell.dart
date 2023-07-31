import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_service.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkbox_cell_bloc.dart';
import '../../../../grid/presentation/layout/sizes.dart';
import '../../cell_builder.dart';

class GridCheckboxCell extends GridCellWidget {
  final CellControllerBuilder cellControllerBuilder;
  GridCheckboxCell({
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key);

  @override
  GridCellState<GridCheckboxCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends GridCellState<GridCheckboxCell> {
  late CheckboxCellBloc _cellBloc;

  @override
  void initState() {
    final cellController =
        widget.cellControllerBuilder.build() as CheckboxCellController;
    _cellBloc = CheckboxCellBloc(
      service: CellBackendService(),
      cellController: cellController,
    )..add(const CheckboxCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<CheckboxCellBloc, CheckboxCellState>(
        builder: (context, state) {
          final icon = state.isSelected
              ? const CheckboxCellCheck()
              : const CheckboxCellUncheck();
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: GridSize.cellContentInsets,
              child: FlowyIconButton(
                hoverColor: Colors.transparent,
                onPressed: () => context
                    .read<CheckboxCellBloc>()
                    .add(const CheckboxCellEvent.select()),
                iconPadding: EdgeInsets.zero,
                icon: icon,
                width: 20,
              ),
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

  @override
  void requestBeginFocus() {
    _cellBloc.add(const CheckboxCellEvent.select());
  }

  @override
  String? onCopy() {
    if (_cellBloc.state.isSelected) {
      return "Yes";
    } else {
      return "No";
    }
  }
}

class CheckboxCellCheck extends StatelessWidget {
  const CheckboxCellCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return svgWidget('editor/editor_check');
  }
}

class CheckboxCellUncheck extends StatelessWidget {
  const CheckboxCellUncheck({super.key});

  @override
  Widget build(BuildContext context) {
    return svgWidget('editor/editor_uncheck');
  }
}
