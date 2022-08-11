import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';

import '../cell_builder.dart';
import 'date_editor.dart';

class DateCellStyle extends GridCellStyle {
  Alignment alignment;

  DateCellStyle({this.alignment = Alignment.center});
}

abstract class GridCellDelegate {
  void onFocus(bool isFocus);
  GridCellDelegate get delegate;
}

class GridDateCell extends GridCellWidget {
  final GridCellControllerBuilder cellControllerBuilder;
  late final DateCellStyle? cellStyle;

  GridDateCell({
    GridCellStyle? style,
    required this.cellControllerBuilder,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as DateCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  GridCellState<GridDateCell> createState() => _DateCellState();
}

class _DateCellState extends GridCellState<GridDateCell> {
  late DateCellBloc _cellBloc;

  @override
  void initState() {
    final cellContext = widget.cellControllerBuilder.build();
    _cellBloc = getIt<DateCellBloc>(param1: cellContext)
      ..add(const DateCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.cellStyle != null
        ? widget.cellStyle!.alignment
        : Alignment.center;
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<DateCellBloc, DateCellState>(
        builder: (context, state) {
          return SizedBox.expand(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _showCalendar(context),
              child: MouseRegion(
                opaque: false,
                cursor: SystemMouseCursors.click,
                child: Align(
                  alignment: alignment,
                  child: FlowyText.medium(state.dateStr, fontSize: 12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCalendar(BuildContext context) {
    final bloc = context.read<DateCellBloc>();
    widget.onCellEditing.value = true;
    final calendar =
        DateCellEditor(onDismissed: () => widget.onCellEditing.value = false);
    calendar.show(
      context,
      cellController: bloc.cellContext.clone(),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }

  @override
  void requestBeginFocus() {}

  @override
  String? onCopy() => _cellBloc.state.dateStr;
}
