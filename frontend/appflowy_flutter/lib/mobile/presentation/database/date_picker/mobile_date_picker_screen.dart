import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/app_bar.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/date_cell_editor_bloc.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/mobile_appflowy_date_picker.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/widgets/mobile_date_header.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileDateCellEditScreen extends StatefulWidget {
  const MobileDateCellEditScreen({
    super.key,
    required this.controller,
    this.showAsFullScreen = true,
  });

  final DateCellController controller;
  final bool showAsFullScreen;

  static const routeName = '/edit_date_cell';

  // the type is DateCellController
  static const dateCellController = 'date_cell_controller';

  // bool value, default is true
  static const fullScreen = 'full_screen';

  @override
  State<MobileDateCellEditScreen> createState() =>
      _MobileDateCellEditScreenState();
}

class _MobileDateCellEditScreenState extends State<MobileDateCellEditScreen> {
  @override
  Widget build(BuildContext context) =>
      widget.showAsFullScreen ? _buildFullScreen() : _buildNotFullScreen();

  Widget _buildFullScreen() {
    return Scaffold(
      appBar: FlowyAppBar(titleText: LocaleKeys.titleBar_date.tr()),
      body: _buildDatePicker(),
    );
  }

  Widget _buildNotFullScreen() {
    return DraggableScrollableSheet(
      expand: false,
      snap: true,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      snapSizes: const [0.4, 0.7, 1.0],
      builder: (_, controller) => Material(
        color: Colors.transparent,
        child: ListView(
          controller: controller,
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: DragHandle()),
            ),
            const MobileDateHeader(),
            _buildDatePicker(),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePicker() => MultiBlocProvider(
        providers: [
          BlocProvider<DateCellEditorBloc>(
            create: (_) => DateCellEditorBloc(
              reminderBloc: getIt<ReminderBloc>(),
              cellController: widget.controller,
            ),
          ),
        ],
        child: BlocBuilder<DateCellEditorBloc, DateCellEditorState>(
          builder: (context, state) {
            return MobileAppFlowyDatePicker(
              selectedDay: state.dateTime,
              dateStr: state.dateStr,
              endDateStr: state.endDateStr,
              timeStr: state.timeStr,
              endTimeStr: state.endTimeStr,
              startDay: state.startDay,
              endDay: state.endDay,
              enableRanges: true,
              isRange: state.isRange,
              includeTime: state.includeTime,
              use24hFormat: state.dateTypeOptionPB.timeFormat ==
                  TimeFormatPB.TwentyFourHour,
              timeFormat: state.dateTypeOptionPB.timeFormat,
              selectedReminderOption: state.reminderOption,
              onStartTimeChanged: (String? time) {
                if (time != null) {
                  context
                      .read<DateCellEditorBloc>()
                      .add(DateCellEditorEvent.setTime(time));
                }
              },
              onEndTimeChanged: (String? time) {
                if (time != null) {
                  context
                      .read<DateCellEditorBloc>()
                      .add(DateCellEditorEvent.setEndTime(time));
                }
              },
              onDaySelected: (selectedDay, focusedDay) => context
                  .read<DateCellEditorBloc>()
                  .add(DateCellEditorEvent.selectDay(selectedDay)),
              onRangeSelected: (start, end, focused) => context
                  .read<DateCellEditorBloc>()
                  .add(DateCellEditorEvent.selectDateRange(start, end)),
              onRangeChanged: (value) => context
                  .read<DateCellEditorBloc>()
                  .add(DateCellEditorEvent.setIsRange(value)),
              onIncludeTimeChanged: (value) => context
                  .read<DateCellEditorBloc>()
                  .add(DateCellEditorEvent.setIncludeTime(value)),
              onClearDate: () => context
                  .read<DateCellEditorBloc>()
                  .add(const DateCellEditorEvent.clearDate()),
              onReminderSelected: (option) =>
                  context.read<DateCellEditorBloc>().add(
                        DateCellEditorEvent.setReminderOption(
                          option: option,
                          selectedDay:
                              state.dateTime == null ? DateTime.now() : null,
                        ),
                      ),
            );
          },
        ),
      );
}
