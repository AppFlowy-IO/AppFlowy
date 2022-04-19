import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/icon_button.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CheckboxCell extends StatefulWidget {
  final GridCell cellData;

  const CheckboxCell({
    required this.cellData,
    Key? key,
  }) : super(key: key);

  @override
  State<CheckboxCell> createState() => _CheckboxCellState();
}

class _CheckboxCellState extends State<CheckboxCell> {
  late CheckboxCellBloc _cellBloc;

  @override
  void initState() {
    _cellBloc = getIt<CheckboxCellBloc>(param1: widget.cellData)..add(const CheckboxCellEvent.initial());
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
              width: 23,
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
