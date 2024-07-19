import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy/plugins/database/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';

import '../../application/cell/bloc/time_cell_editor_bloc.dart';
import '../../application/cell/bloc/time_cell_bloc.dart';

class TimeCellEditor extends StatefulWidget {
  const TimeCellEditor({required this.cellController, super.key});

  final TimeCellController cellController;

  @override
  State<TimeCellEditor> createState() => _TimeCellEditorState();
}

class _TimeCellEditorState extends State<TimeCellEditor> {
  final TextEditingController _timeStartEditingController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timeStartEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TimeCellEditorBloc(
        cellController: widget.cellController,
      ),
      child: BlocBuilder<TimeCellEditorBloc, TimeCellEditorState>(
        builder: (context, state) {
          final cellBlocState = context.watch<TimeCellBloc>().state;
          _timeStartEditingController.text = formatTime(
            state.timerStart ?? 0,
            cellBlocState.precision,
          );

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (cellBlocState.timeType == TimeTypePB.Timer)
                ..._buildTimerStart(context),
              ..._buildTimeTracks(
                state.timeTracks.where((tt) => tt.toTimestamp != 0).toList(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                child: _TimeTrackInput(
                  text: 'Add new',
                  onSubmitted: (date, duration) => context
                      .read<TimeCellEditorBloc>()
                      .add(TimeCellEditorEvent.addTimeTrack(date, duration)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _buildTimerStart(BuildContext context) {
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
        child: Row(
          children: [
            const FlowyText('Timer start:'),
            Container(
              padding: const EdgeInsets.only(left: 8),
              width: 180,
              child: FlowyTextField(
                controller: _timeStartEditingController,
                autoFocus: false,
                submitOnLeave: true,
                onSubmitted: (timeStr) {
                  final timerStart = parseTimeToSeconds(
                    timeStr,
                    context.read<TimeCellBloc>().state.precision,
                  );
                  if (timerStart == null) {
                    return;
                  }

                  context.read<TimeCellEditorBloc>().add(
                        TimeCellEditorEvent.updateTimer(timerStart),
                      );
                },
              ),
            ),
          ],
        ),
      ),
      const TypeOptionSeparator(spacing: 4.0),
    ];
  }

  List<Widget> _buildTimeTracks(List<TimeTrackPB> timeTracks) {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 4),
        child: FlowyText.semibold('Time tracks'),
      ),
      if (timeTracks.isNotEmpty) ...[
        Column(
          children: timeTracks.map((tt) => _TimeTrack(timeTrack: tt)).toList(),
        ),
        const TypeOptionSeparator(spacing: 4.0),
      ],
    ];
  }
}

class _TimeTrack extends StatefulWidget {
  const _TimeTrack({required this.timeTrack});

  final TimeTrackPB timeTrack;

  @override
  State<_TimeTrack> createState() => _TimeTrackState();
}

class _TimeTrackState extends State<_TimeTrack> {
  bool isEditing = false;

  late DateTime date;
  late int duration;

  @override
  Widget build(BuildContext context) {
    date = DateTime.fromMillisecondsSinceEpoch(
      widget.timeTrack.fromTimestamp.toInt() * 1000,
    );
    duration =
        (widget.timeTrack.toTimestamp - widget.timeTrack.fromTimestamp).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEditing) _buildEditTimeTrack() else ..._buildViewTimeTrack(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FlowyIconButton(
              icon: isEditing
                  ? const FlowySvg(FlowySvgs.close_s)
                  : const FlowySvg(FlowySvgs.edit_s),
              onPressed: () => setState(() => isEditing = !isEditing),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FlowyIconButton(
              icon: const FlowySvg(FlowySvgs.trash_s),
              onPressed: () {
                context.read<TimeCellEditorBloc>().add(
                      TimeCellEditorEvent.deleteTimeTrack(widget.timeTrack.id),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildViewTimeTrack() {
    return [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        width: 120,
        child: FlowyText.medium(
          DateFormat("dd/mm/yy").add_Hm().format(date),
          color: AFThemeExtension.of(context).secondaryTextColor,
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        width: 120,
        child: FlowyText.medium(
          formatTimeSeconds(
            duration,
            context.watch<TimeCellBloc>().state.precision,
          ),
          color: AFThemeExtension.of(context).secondaryTextColor,
        ),
      ),
    ];
  }

  Widget _buildEditTimeTrack() {
    return _TimeTrackInput(
      date: date,
      duration: duration,
      icon: const FlowySvg(FlowySvgs.checkmark_tiny_s),
      onSubmitted: (date, duration) {
        context.read<TimeCellEditorBloc>().add(
              TimeCellEditorEvent.updateTimeTrack(
                widget.timeTrack.id,
                date,
                duration,
              ),
            );
        setState(() => isEditing = false);
      },
    );
  }
}

class _TimeTrackInput extends StatefulWidget {
  const _TimeTrackInput({
    this.date,
    this.duration,
    this.text,
    this.icon,
    required this.onSubmitted,
  });

  final DateTime? date;
  final int? duration;
  final String? text;
  final Widget? icon;
  final Function(DateTime, int) onSubmitted;

  @override
  State<_TimeTrackInput> createState() => _TimeTrackInputState();
}

class _TimeTrackInputState extends State<_TimeTrackInput> {
  final PopoverController _popover = PopoverController();

  final TextEditingController _dateEditingController = TextEditingController();
  final TextEditingController _durationEditingController =
      TextEditingController();

  DateTime? _selectedDay;
  String? _timeStr;
  String? _timeError;

  DateTime? _date;
  int? _duration;

  @override
  void initState() {
    _date = widget.date;
    _duration = widget.duration;

    super.initState();
  }

  @override
  void dispose() {
    _dateEditingController.dispose();
    _durationEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_date != null) {
      _updateDateText();
    }
    if (_duration != null) {
      _updateDurationText(context.read<TimeCellBloc>().state.precision);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppFlowyPopover(
          controller: _popover,
          triggerActions: PopoverTriggerFlags.none,
          direction: PopoverDirection.bottomWithLeftAligned,
          constraints: BoxConstraints.loose(const Size(260, 620)),
          margin: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            width: 120,
            child: FlowyTextField(
              readOnly: true,
              onTap: _popover.show,
              textStyle: Theme.of(context)
                  .textTheme
                  .bodyMedium!
                  .copyWith(fontSize: 12),
              controller: _dateEditingController,
              autoFocus: false,
              hintText: 'Date',
            ),
          ),
          popupBuilder: (BuildContext popoverContent) {
            return StatefulBuilder(
              builder: (context, setNewState) => AppFlowyDatePicker(
                selectedDay: _selectedDay,
                timeStr: _timeStr,
                timeHintText: 'Started from (11:30)',
                parseTimeError: _timeError,
                includeTime: true,
                dateFormat: DateFormatPB.Friendly,
                timeFormat: TimeFormatPB.TwentyFourHour,
                onIncludeTimeChanged: (_) => {},
                onDaySelected: (selectedDay, _) => setNewState(() {
                  _selectedDay = selectedDay;
                  if (_timeStr == null) {
                    _timeError = "started from time is required";
                    return;
                  }

                  _popover.close();
                }),
                onStartTimeSubmitted: (time) => setNewState(() {
                  _timeStr = time == "" ? null : time;
                  if (_timeStr != null) {
                    _timeError = null;
                  }
                }),
              ),
            );
          },
          onClose: () {
            if (_timeStr == null || _selectedDay == null) {
              _dateEditingController.text = "";
              return;
            }

            _timeStr = _timeStr!.contains(":") ? _timeStr : "$_timeStr:00";
            final time = _timeStr!.split(":");
            final hour = int.parse(time[0]);
            final minute = int.parse(time[1]);
            _date = DateTime(
              _selectedDay!.year,
              _selectedDay!.month,
              _selectedDay!.day,
              hour,
              minute,
            );

            _updateDateText();
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          width: 120,
          child: FlowyTextField(
            textStyle:
                Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 12),
            controller: _durationEditingController,
            onTap: _popover.close,
            hintText: 'Duration (20m)',
            autoFocus: false,
            submitOnLeave: true,
            onSubmitted: (durationStr) {
              final precision = context.read<TimeCellBloc>().state.precision;

              _duration = parseTimeToSeconds(durationStr, precision);
              if (_duration == null) {
                _durationEditingController.text = "";
                return;
              }

              _updateDurationText(precision);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: widget.text != null
              ? FlowyTextButton(widget.text!, onPressed: _onPressed)
              : FlowyIconButton(icon: widget.icon!, onPressed: _onPressed),
        ),
      ],
    );
  }

  void _onPressed() {
    if (_date == null || _duration == null) {
      return;
    }

    widget.onSubmitted(_date!, _duration!);

    _date = null;
    _duration = null;
    _dateEditingController.text = "";
    _durationEditingController.text = "";
  }

  void _updateDateText() {
    _dateEditingController.text =
        DateFormat("dd/mm/yy").add_Hm().format(_date!);
  }

  void _updateDurationText(TimePrecisionPB precision) {
    _durationEditingController.text = formatTimeSeconds(_duration!, precision);
  }
}
