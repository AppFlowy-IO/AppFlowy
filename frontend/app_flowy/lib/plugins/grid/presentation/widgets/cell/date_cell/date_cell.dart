import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/plugins/grid/application/prelude.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

import '../../../layout/sizes.dart';
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
  late PopoverController _popover;
  late DateCellBloc _cellBloc;

  @override
  void initState() {
    _popover = PopoverController();
    final cellController =
        widget.cellControllerBuilder.build() as GridDateCellController;
    _cellBloc = getIt<DateCellBloc>(param1: cellController)
      ..add(const DateCellEvent.initial());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.cellStyle != null
        ? widget.cellStyle!.alignment
        : Alignment.centerLeft;
    return BlocProvider.value(
      value: _cellBloc,
      child: BlocBuilder<DateCellBloc, DateCellState>(
        builder: (context, state) {
          return AppFlowyPopover(
            controller: _popover,
            triggerActions: PopoverTriggerFlags.none,
            direction: PopoverDirection.bottomWithLeftAligned,
            constraints: BoxConstraints.loose(const Size(320, 520)),
            margin: EdgeInsets.zero,
            child: SizedBox.expand(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _popover.show(),
                child: Align(
                  alignment: alignment,
                  child: Padding(
                    padding: GridSize.cellContentInsets,
                    child: FlowyText.medium(
                      state.dateStr,
                      fontSize: FontSizes.s14,
                    ),
                  ),
                ),
              ),
            ),
            popupBuilder: (BuildContext popoverContent) {
              return DateCellEditor(
                cellController: widget.cellControllerBuilder.build()
                    as GridDateCellController,
                onDismissed: () => widget.onCellEditing.value = false,
              );
            },
            onClose: () {
              widget.onCellEditing.value = false;
            },
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
  void requestBeginFocus() {}

  @override
  String? onCopy() => _cellBloc.state.dateStr;
}
