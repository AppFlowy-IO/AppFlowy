import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/database/card/row/cells/date_cell/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/date.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/date_cal_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/mobile_date_editor.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MobileDateCellEditScreen extends StatefulWidget {
  static const routeName = '/edit_date_cell';

  // the type is DateCellController
  static const argCellController = 'cell_controller';

  const MobileDateCellEditScreen({
    super.key,
    required this.cellController,
  });

  final DateCellController cellController;

  @override
  State<MobileDateCellEditScreen> createState() =>
      _MobileDateCellEditScreenState();
}

class _MobileDateCellEditScreenState extends State<MobileDateCellEditScreen> {
  late final Future<Either<dynamic, FlowyError>> typeOptionFuture;

  @override
  void initState() {
    super.initState();

    typeOptionFuture = widget.cellController.getTypeOption(
      DateTypeOptionDataParser(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.titleBar_date.tr()),
      ),
      body: FutureBuilder<Either<dynamic, FlowyError>>(
        future: typeOptionFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          return data.fold(
            (dateTypeOptionPB) {
              return _DateCellEditBody(
                dateCellController: widget.cellController,
                dateTypeOptionPB: dateTypeOptionPB,
              );
            },
            (err) {
              Log.error(err);
              return FlowyMobileStateContainer.error(
                title: LocaleKeys.grid_field_failedToLoadDate.tr(),
                errorMsg: err.toString(),
              );
            },
          );
        },
      ),
    );
  }
}

class _DateCellEditBody extends StatelessWidget {
  const _DateCellEditBody({
    required this.dateCellController,
    required this.dateTypeOptionPB,
  });

  final DateCellController dateCellController;
  final DateTypeOptionPB dateTypeOptionPB;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DateCellCalendarBloc(
        dateTypeOptionPB: dateTypeOptionPB,
        cellData: dateCellController.getCellData(),
        cellController: dateCellController,
      )..add(const DateCellCalendarEvent.initial()),
      child: Column(
        children: [
          const FlowyOptionDecorateBox(
            child: MobileDatePicker(),
          ),
          VSpace(
            20.0,
            color: Theme.of(context).colorScheme.secondaryContainer,
          ),
          const _EndDateSwitch(),
          const _IncludeTimeSwitch(),
          const _StartDayTime(),
          const _EndDayTime(),
          const Divider(),
          const _DateFormatOption(),
          const _TimeFormatOption(),
          const Divider(),
          const _ClearDateButton(),
        ],
      ),
    );
  }
}

class _EndDateSwitch extends StatelessWidget {
  const _EndDateSwitch();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DateCellCalendarBloc, DateCellCalendarState, bool>(
      selector: (state) => state.isRange,
      builder: (context, isRange) {
        return Row(
          children: [
            FlowyText(
              LocaleKeys.grid_field_isRange.tr(),
              // style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Switch.adaptive(
              value: isRange,
              activeColor: Theme.of(context).colorScheme.primary,
              onChanged: (value) {
                context
                    .read<DateCellCalendarBloc>()
                    .add(DateCellCalendarEvent.setIsRange(value));
              },
            ),
          ],
        );
      },
    );
  }
}

class _IncludeTimeSwitch extends StatelessWidget {
  const _IncludeTimeSwitch();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DateCellCalendarBloc, DateCellCalendarState, bool>(
      selector: (state) => state.includeTime,
      builder: (context, includeTime) {
        return IncludeTimeSwitch(
          switchValue: includeTime,
          onChanged: (value) {
            context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.setIncludeTime(value));
          },
        );
      },
    );
  }
}

class _StartDayTime extends StatelessWidget {
  const _StartDayTime();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateCellCalendarBloc, DateCellCalendarState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.includeTime
              ? Row(
                  children: [
                    Text(
                      state.isRange
                          ? LocaleKeys.grid_field_startDateTime.tr()
                          : LocaleKeys.grid_field_dateTime.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    // TODO(yijing): improve width
                    SizedBox(
                      width: 180,
                      child: _TimeTextField(
                        timeStr: state.timeStr,
                        isEndTime: false,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _EndDayTime extends StatelessWidget {
  const _EndDayTime();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateCellCalendarBloc, DateCellCalendarState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: state.includeTime && state.endTimeStr != null
              ? Row(
                  children: [
                    Text(
                      LocaleKeys.grid_field_endDateTime.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    // TODO(yijing): improve width
                    SizedBox(
                      width: 180,
                      child: _TimeTextField(
                        timeStr: state.timeStr,
                        isEndTime: true,
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _TimeTextField extends StatefulWidget {
  const _TimeTextField({
    required this.timeStr,
    required this.isEndTime,
  });

  final String? timeStr;
  final bool isEndTime;

  @override
  State<_TimeTextField> createState() => _TimeTextFieldState();
}

class _TimeTextFieldState extends State<_TimeTextField> {
  late final TextEditingController _textController =
      TextEditingController(text: widget.timeStr);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DateCellCalendarBloc, DateCellCalendarState>(
      listener: (context, state) {
        _textController.text =
            widget.isEndTime ? state.endTimeStr ?? "" : state.timeStr ?? "";
      },
      builder: (context, state) {
        return TextFormField(
          controller: _textController,
          textAlign: TextAlign.end,
          decoration: InputDecoration(
            hintText: state.timeHintText,
            errorText: widget.isEndTime
                ? state.parseEndTimeError
                : state.parseTimeError,
          ),
          keyboardType: TextInputType.datetime,
          onFieldSubmitted: (timeStr) {
            context.read<DateCellCalendarBloc>().add(
                  widget.isEndTime
                      ? DateCellCalendarEvent.setEndTime(timeStr)
                      : DateCellCalendarEvent.setTime(timeStr),
                );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class _ClearDateButton extends StatelessWidget {
  const _ClearDateButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          LocaleKeys.grid_field_clearDate.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      onTap: () => context
          .read<DateCellCalendarBloc>()
          .add(const DateCellCalendarEvent.clearDate()),
    );
  }
}

class _TimeFormatOption extends StatelessWidget {
  const _TimeFormatOption();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DateCellCalendarBloc, DateCellCalendarState,
        TimeFormatPB>(
      selector: (state) => state.dateTypeOptionPB.timeFormat,
      builder: (context, state) {
        return TimeFormatListTile(
          currentFormatStr: state.title(),
          groupValue: context
              .watch<DateCellCalendarBloc>()
              .state
              .dateTypeOptionPB
              .timeFormat,
          onChanged: (newFormat) {
            if (newFormat == null) return;
            context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.setTimeFormat(newFormat));
          },
        );
      },
    );
  }
}

class _DateFormatOption extends StatelessWidget {
  const _DateFormatOption();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DateCellCalendarBloc, DateCellCalendarState,
        DateFormatPB>(
      selector: (state) => state.dateTypeOptionPB.dateFormat,
      builder: (context, state) {
        return DateFormatListTile(
          currentFormatStr: state.title(),
          groupValue: context
              .watch<DateCellCalendarBloc>()
              .state
              .dateTypeOptionPB
              .dateFormat,
          onChanged: (newFormat) {
            if (newFormat == null) return;
            context
                .read<DateCellCalendarBloc>()
                .add(DateCellCalendarEvent.setDateFormat(newFormat));
          },
        );
      },
    );
  }
}
