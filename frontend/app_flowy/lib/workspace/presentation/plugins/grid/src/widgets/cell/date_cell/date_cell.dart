import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/prelude.dart';

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

class DateCell extends StatefulWidget with GridCellWidget {
  final GridCellContextBuilder cellContextBuilder;
  late final DateCellStyle? cellStyle;

  DateCell({
    GridCellStyle? style,
    required this.cellContextBuilder,
    Key? key,
  }) : super(key: key) {
    if (style != null) {
      cellStyle = (style as DateCellStyle);
    } else {
      cellStyle = null;
    }
  }

  @override
  State<DateCell> createState() => _DateCellState();
}

class _DateCellState extends State<DateCell> {
  late DateCellBloc _cellBloc;

  @override
  void initState() {
    final cellContext = widget.cellContextBuilder.build();
    _cellBloc = getIt<DateCellBloc>(param1: cellContext)..add(const DateCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.cellStyle != null ? widget.cellStyle!.alignment : Alignment.center;
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
    widget.isFocus.value = true;
    final calendar = DateCellEditor(onDismissed: () => widget.isFocus.value = false);
    calendar.show(
      context,
      cellContext: bloc.cellContext.clone(),
    );
  }

  @override
  Future<void> dispose() async {
    _cellBloc.close();
    super.dispose();
  }
}
