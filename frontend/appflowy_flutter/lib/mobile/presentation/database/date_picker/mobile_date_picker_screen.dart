import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database_view/application/cell/cell_controller_builder.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/date_cell_editor_bloc.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/date_cell/mobile_date_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class MobileDateCellEditScreen extends StatefulWidget {
  static const routeName = '/edit_date_cell';

  // the type is DateCellController
  static const dateCellController = 'date_cell_controller';
  // bool value, default is true
  static const fullScreen = 'full_screen';

  const MobileDateCellEditScreen({
    super.key,
    required this.controller,
    this.showAsFullScreen = true,
  });

  final DateCellController controller;
  final bool showAsFullScreen;

  @override
  State<MobileDateCellEditScreen> createState() =>
      _MobileDateCellEditScreenState();
}

class _MobileDateCellEditScreenState extends State<MobileDateCellEditScreen> {
  @override
  Widget build(BuildContext context) {
    return widget.showAsFullScreen ? _buildFullScreen() : _buildNotFullScreen();
  }

  Widget _buildFullScreen() {
    return Scaffold(
      appBar: AppBar(
        title: FlowyText.medium(
          LocaleKeys.titleBar_date.tr(),
        ),
      ),
      body: _DateCellEditBody(
        dateCellController: widget.controller,
      ),
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
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: ListView(
          controller: controller,
          children: [
            ColoredBox(
              color: Theme.of(context).colorScheme.surface,
              child: const Center(child: DragHandler()),
            ),
            _buildHeader(),
            Expanded(
              child: _DateCellEditBody(
                dateCellController: widget.controller,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const iconWidth = 30.0;
    const height = 44.0;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: FlowyIconButton(
              icon: const FlowySvg(
                FlowySvgs.close_s,
                size: Size.square(iconWidth),
              ),
              width: iconWidth,
              iconPadding: EdgeInsets.zero,
              onPressed: () => context.pop(),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: FlowyText.medium(
              LocaleKeys.grid_field_dateFieldName.tr(),
              fontSize: 16,
            ),
          ),
        ].map((e) => SizedBox(height: height, child: e)).toList(),
      ),
    );
  }
}

class _DateCellEditBody extends StatelessWidget {
  const _DateCellEditBody({
    required this.dateCellController,
  });

  final DateCellController dateCellController;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DateCellEditorBloc(
        cellController: dateCellController,
      )..add(const DateCellEditorEvent.initial()),
      child: const Column(
        children: [
          FlowyOptionDecorateBox(
            showTopBorder: false,
            child: _IncludeTimePicker(),
          ),
          _Divider(),
          FlowyOptionDecorateBox(
            child: MobileDatePicker(),
          ),
          _Divider(),
          _EndDateSwitch(),
          _IncludeTimeSwitch(),
          _Divider(),
          _ClearDateButton(),
          _Divider(),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const VSpace(20.0);
  }
}

class _IncludeTimePicker extends StatefulWidget {
  const _IncludeTimePicker();

  @override
  State<_IncludeTimePicker> createState() => _IncludeTimePickerState();
}

class _IncludeTimePickerState extends State<_IncludeTimePicker> {
  String? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateCellEditorBloc, DateCellEditorState>(
      builder: (context, state) {
        final startDay = state.dateStr;
        final endDay = state.endDateStr;
        final includeTime = state.includeTime;
        final use24hFormat =
            state.dateTypeOptionPB.timeFormat == TimeFormatPB.TwentyFourHour;
        if (startDay == null || startDay.isEmpty) {
          return const Divider(
            height: 1,
          );
        }
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTime(
                context,
                includeTime,
                use24hFormat,
                true,
                startDay,
                state.timeStr,
              ),
              VSpace(
                8.0,
                color: Theme.of(context).colorScheme.surface,
              ),
              _buildTime(
                context,
                includeTime,
                use24hFormat,
                false,
                endDay,
                state.endTimeStr,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTime(
    BuildContext context,
    bool isIncludeTime,
    bool use24hFormat,
    bool isStartDay,
    String? dateStr,
    String? timeStr,
  ) {
    if (dateStr == null) {
      return const SizedBox.shrink();
    }

    final List<Widget> children = [];

    if (!isIncludeTime) {
      children.addAll([
        const HSpace(12.0),
        FlowyText(
          dateStr,
        ),
      ]);
    } else {
      children.addAll([
        Expanded(
          child: FlowyText(
            dateStr,
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          width: 1,
          height: 16,
          color: Colors.grey,
        ),
        Expanded(
          child: FlowyText(
            timeStr ?? '',
            textAlign: TextAlign.center,
          ),
        ),
      ]);
    }

    return GestureDetector(
      onTap: () async {
        final bloc = context.read<DateCellEditorBloc>();
        await showMobileBottomSheet(
          context,
          builder: (context) {
            return ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 300,
              ),
              child: CupertinoDatePicker(
                showDayOfWeek: false,
                mode: CupertinoDatePickerMode.time,
                use24hFormat: use24hFormat,
                onDateTimeChanged: (dateTime) {
                  _selectedTime = use24hFormat
                      ? DateFormat('HH:mm').format(dateTime)
                      : DateFormat('hh:mm a').format(dateTime);
                },
              ),
            );
          },
        );

        if (_selectedTime != null) {
          bloc.add(
            isStartDay
                ? DateCellEditorEvent.setTime(_selectedTime!)
                : DateCellEditorEvent.setEndTime(_selectedTime!),
          );
        }
      },
      child: Container(
        constraints: const BoxConstraints(
          minHeight: 36,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          color: Theme.of(context).colorScheme.secondaryContainer,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Row(
          children: children,
        ),
      ),
    );
  }
}

class _EndDateSwitch extends StatelessWidget {
  const _EndDateSwitch();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DateCellEditorBloc, DateCellEditorState, bool>(
      selector: (state) => state.isRange,
      builder: (context, isRange) {
        return FlowyOptionTile.toggle(
          text: LocaleKeys.grid_field_isRange.tr(),
          isSelected: isRange,
          onValueChanged: (value) {
            context
                .read<DateCellEditorBloc>()
                .add(DateCellEditorEvent.setIsRange(value));
          },
        );
      },
    );
  }
}

class _IncludeTimeSwitch extends StatelessWidget {
  const _IncludeTimeSwitch();

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DateCellEditorBloc, DateCellEditorState, bool>(
      selector: (state) => state.includeTime,
      builder: (context, includeTime) {
        return FlowyOptionTile.toggle(
          showTopBorder: false,
          text: LocaleKeys.grid_field_includeTime.tr(),
          isSelected: includeTime,
          onValueChanged: (value) {
            context
                .read<DateCellEditorBloc>()
                .add(DateCellEditorEvent.setIncludeTime(value));
          },
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
    return BlocConsumer<DateCellEditorBloc, DateCellEditorState>(
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
            context.read<DateCellEditorBloc>().add(
                  widget.isEndTime
                      ? DateCellEditorEvent.setEndTime(timeStr)
                      : DateCellEditorEvent.setTime(timeStr),
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
    return FlowyOptionTile.text(
      text: LocaleKeys.grid_field_clearDate.tr(),
      onTap: () => context
          .read<DateCellEditorBloc>()
          .add(const DateCellEditorEvent.clearDate()),
    );
  }
}
