import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'cell_builder.dart';

class CheckboxCell extends GridCellWidget {
  final GridCellContextBuilder cellContextBuilder;
  CheckboxCell({
    required this.cellContextBuilder,
    Key? key,
  }) : super(key: key);

  @override
  GridCellState<CheckboxCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends GridCellState<CheckboxCell> {
  late CheckboxCellBloc _cellBloc;

  @override
  void initState() {
    final cellContext = widget.cellContextBuilder.build();
    _cellBloc = getIt<CheckboxCellBloc>(param1: cellContext)..add(const CheckboxCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<CheckboxCellBloc, CheckboxCellState>(
        builder: (context, state) {
          final icon = state.isSelected ? svgWidget('editor/editor_check') : svgWidget('editor/editor_uncheck');
          return Align(
            alignment: Alignment.centerLeft,
            child: FlowyIconButton(
              onPressed: () => context.read<CheckboxCellBloc>().add(const CheckboxCellEvent.select()),
              iconPadding: EdgeInsets.zero,
              icon: icon,
              width: 20,
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
