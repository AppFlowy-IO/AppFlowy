import 'package:appflowy/plugins/database/application/cell/bloc/date_cell_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/date_cell_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_builder.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../desktop_grid/desktop_grid_date_cell.dart';
import '../desktop_row_detail/desktop_row_detail_date_cell.dart';
import '../mobile_grid/mobile_grid_date_cell.dart';
import '../mobile_row_detail/mobile_row_detail_date_cell.dart';

abstract class IEditableDateCellSkin {
  const IEditableDateCellSkin();

  factory IEditableDateCellSkin.fromStyle(EditableCellStyle style) {
    return switch (style) {
      EditableCellStyle.desktopGrid => DesktopGridDateCellSkin(),
      EditableCellStyle.desktopRowDetail => DesktopRowDetailDateCellSkin(),
      EditableCellStyle.mobileGrid => MobileGridDateCellSkin(),
      EditableCellStyle.mobileRowDetail => MobileRowDetailDateCellSkin(),
    };
  }

  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    ValueNotifier<bool> compactModeNotifier,
    DateCellBloc bloc,
    DateCellState state,
    PopoverController popoverController,
  );
}

class EditableDateCell extends EditableCellWidget {
  EditableDateCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.skin,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final IEditableDateCellSkin skin;

  @override
  GridCellState<EditableDateCell> createState() => _DateCellState();
}

class _DateCellState extends GridCellState<EditableDateCell> {
  final PopoverController _popover = PopoverController();
  late final cellBloc = DateCellBloc(
    cellController: makeCellController(
      widget.databaseController,
      widget.cellContext,
    ).as(),
  );

  @override
  void dispose() {
    cellBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: cellBloc,
      child: BlocBuilder<DateCellBloc, DateCellState>(
        builder: (context, state) {
          return widget.skin.build(
            context,
            widget.cellContainerNotifier,
            widget.databaseController.compactModeNotifier,
            cellBloc,
            state,
            _popover,
          );
        },
      ),
    );
  }

  @override
  void onRequestFocus() {
    _popover.show();
    widget.cellContainerNotifier.isFocus = true;
  }

  @override
  String? onCopy() => getDateCellStrFromCellData(
        cellBloc.state.fieldInfo,
        cellBloc.state.cellData,
      );
}

String getDateCellStrFromCellData(FieldInfo field, DateCellData cellData) {
  if (cellData.dateTime == null) {
    return "";
  }

  final DateTypeOptionPB(:dateFormat, :timeFormat) =
      DateTypeOptionDataParser().fromBuffer(field.field.typeOptionData);

  final format = cellData.includeTime
      ? DateFormat("${dateFormat.pattern} ${timeFormat.pattern}")
      : DateFormat(dateFormat.pattern);

  if (cellData.isRange) {
    return "${format.format(cellData.dateTime!)} → ${format.format(cellData.endDateTime!)}";
  } else {
    return format.format(cellData.dateTime!);
  }
}

/// Returns a human-readable string representing the time remaining until the given date
/// or how long overdue it is
/// e.g., "3 days left", "2 hours left", "5 minutes left" (for future dates)
///       "2 days overdue", "3 hours overdue" (for past dates)
/// Returns an empty string if cellData.dateTime is null
String getTimeRemainingFromCellData(DateCellData cellData) {
  if (cellData.dateTime == null) {
    return "";
  }

  final now = DateTime.now();
  final targetDate = cellData.dateTime!;
  final difference = targetDate.difference(now);

  // Calculate absolute time difference
  final absDifference = difference.abs();
  final days = absDifference.inDays;
  final hours = absDifference.inHours;
  final minutes = absDifference.inMinutes;

  // Determine if it's overdue or upcoming
  final isOverdue = difference.isNegative;

  if (days > 0) {
    return "$days day${days == 1 ? '' : 's'} ${isOverdue ? 'overdue' : 'left'}";
  } else if (hours > 0) {
    return "$hours hour${hours == 1 ? '' : 's'} ${isOverdue ? 'overdue' : 'left'}";
  } else if (minutes > 0) {
    return "$minutes min${minutes == 1 ? '' : 's'} ${isOverdue ? 'overdue' : 'left'}";
  } else {
    return isOverdue ? "Overdue" : "Less than a minute";
  }
}

extension GetDateFormatExtension on DateFormatPB {
  String get pattern => switch (this) {
        DateFormatPB.Local => 'MM/dd/y',
        DateFormatPB.US => 'y/MM/dd',
        DateFormatPB.ISO => 'y-MM-dd',
        DateFormatPB.Friendly => 'MMM dd, y',
        DateFormatPB.DayMonthYear => 'dd/MM/y',
        _ => 'MMM dd, y',
      };
}

extension GetTimeFormatExtension on TimeFormatPB {
  String get pattern => switch (this) {
        TimeFormatPB.TwelveHour => 'hh:mm a',
        _ => 'HH:mm',
      };
}
