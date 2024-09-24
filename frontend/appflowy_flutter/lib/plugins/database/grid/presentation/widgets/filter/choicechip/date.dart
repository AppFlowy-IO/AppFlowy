import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/application/filter/date_filter_editor_bloc.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy/util/int64_extension.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';
import '../filter_info.dart';

import 'choicechip.dart';

class DateFilterChoicechip extends StatefulWidget {
  const DateFilterChoicechip({
    super.key,
    required this.filterInfo,
  });

  final String filterId;

  @override
  State<DateFilterChoicechip> createState() => _DateFilterChoicechipState();
}

class _DateFilterChoicechipState extends State<DateFilterChoicechip> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DateFilterEditorBloc(filterInfo: widget.filterInfo),
      child: BlocBuilder<DateFilterEditorBloc, DateFilterEditorState>(
        builder: (context, state) {
          return AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(200, 120)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (_) {
              return BlocProvider.value(
                value: context.read<DateFilterEditorBloc>(),
                child: const DateFilterEditor(),
              );
            },
            child: ChoiceChipButton(filterInfo: state.filterInfo),
          );
        },
      ),
    );
  }
}

class DateFilterEditor extends StatefulWidget {
  const DateFilterEditor({super.key});

  @override
  State<DateFilterEditor> createState() => _DateFilterEditorState();
}

class _DateFilterEditorState extends State<DateFilterEditor> {
  final popoverMutex = PopoverMutex();
  final _popover = PopoverController();
  final _textEditingController = TextEditingController();

  @override
  void dispose() {
    popoverMutex.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DateFilterEditorBloc, DateFilterEditorState>(
      builder: (context, state) {
        final List<Widget> children = [
          _buildFilterPanel(context),
          if (state.filter.condition != DateFilterConditionPB.DateIsEmpty &&
              state.filter.condition !=
                  DateFilterConditionPB.DateIsNotEmpty) ...[
            const VSpace(4),
            _buildFilterDateField(context),
          ],
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: IntrinsicHeight(child: Column(children: children)),
        );
      },
    );
  }

  Widget _buildFilterPanel(BuildContext context) {
    final state = context.watch<DateFilterEditorBloc>().state;
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: FlowyText(
              state.filterInfo.fieldInfo.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(4),
          Expanded(
            child: DateFilterConditionPBList(
              filterInfo: state.filterInfo,
              popoverMutex: popoverMutex,
              onCondition: (condition) {
                context
                    .read<DateFilterEditorBloc>()
                    .add(DateFilterEditorEvent.updateCondition(condition));
                _popover.close();
              },
            ),
          ),
          const HSpace(4),
          DisclosureButton(
            popoverMutex: popoverMutex,
            onAction: (action) {
              switch (action) {
                case FilterDisclosureAction.delete:
                  context
                      .read<DateFilterEditorBloc>()
                      .add(const DateFilterEditorEvent.delete());
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDateField(BuildContext context) {
    final filter = context.watch<DateFilterEditorBloc>().state.filter;

    final isRange = filter.condition == DateFilterConditionPB.DateWithIn;
    String? text;

    if (isRange) {
      text =
          "${filter.start.dateTime.defaultFormat ?? ""} - ${filter.end.dateTime.defaultFormat ?? ""}";
      text = text == " - " ? null : text;
    } else {
      text = filter.timestamp.dateTime.defaultFormat;
    }
    _textEditingController.text = text ?? "";

    return AppFlowyPopover(
      controller: _popover,
      triggerActions: PopoverTriggerFlags.none,
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: BoxConstraints.loose(const Size(260, 620)),
      margin: EdgeInsets.zero,
      child: FlowyTextField(
        controller: _textEditingController,
        readOnly: true,
        onTap: _popover.show,
        autoFocus: false,
        hintText: LocaleKeys.grid_field_dateTime.tr(),
      ),
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<DateFilterEditorBloc>(),
          child: BlocBuilder<DateFilterEditorBloc, DateFilterEditorState>(
            builder: (context, state) {
              final filter = state.filter;
              final isRange =
                  filter.condition == DateFilterConditionPB.DateWithIn;

              return AppFlowyDatePicker(
                isRange: isRange,
                timeHintText: LocaleKeys.grid_field_selectTime.tr(),
                includeTime: false,
                dateFormat: DateFormatPB.Friendly,
                timeFormat: TimeFormatPB.TwentyFourHour,
                selectedDay: filter.timestamp.dateTime,
                startDay: isRange ? filter.start.dateTime : null,
                endDay: isRange ? filter.end.dateTime : null,
                onDaySelected: (selectedDay, _) {
                  Function(DateTime) event =
                      (date) => DateFilterEditorEvent.updateDate(date);
                  if (isRange) {
                    event = (date) =>
                        DateFilterEditorEvent.updateRange(start: date);
                  }

                  context.read<DateFilterEditorBloc>().add(event(selectedDay));
                  if (isRange) {
                    _popover.close();
                  }
                },
                onRangeSelected: (start, end, _) =>
                    context.read<DateFilterEditorBloc>().add(
                          DateFilterEditorEvent.updateRange(
                            start: start,
                            end: end,
                          ),
                        ),
                onIncludeTimeChanged: (_) => {},
              );
            },
          ),
        );
      },
    );
  }
}

class DateFilterConditionPBList extends StatelessWidget {
  const DateFilterConditionPBList({
    super.key,
    required this.filterInfo,
    required this.popoverMutex,
    required this.onCondition,
  });

  final FilterInfo filterInfo;
  final PopoverMutex popoverMutex;
  final Function(DateFilterConditionPB) onCondition;

  @override
  Widget build(BuildContext context) {
    final dateFilter = filterInfo.dateFilter()!;
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: DateFilterConditionPB.values
          .map(
            (action) => ConditionWrapper(
              action,
              dateFilter.condition == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: dateFilter.condition.filterName,
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) {
        onCondition(action.inner);
        controller.close();
      },
    );
  }
}

class ConditionWrapper extends ActionCell {
  ConditionWrapper(this.inner, this.isSelected);

  final DateFilterConditionPB inner;
  final bool isSelected;

  @override
  Widget? rightIcon(Color iconColor) =>
      isSelected ? const FlowySvg(FlowySvgs.check_s) : null;

  @override
  String get name => inner.filterName;
}

extension DateFilterConditionPBExtension on DateFilterConditionPB {
  String get filterName {
    return switch (this) {
      DateFilterConditionPB.DateIs => LocaleKeys.grid_dateFilter_is.tr(),
      DateFilterConditionPB.DateBefore =>
        LocaleKeys.grid_dateFilter_before.tr(),
      DateFilterConditionPB.DateAfter => LocaleKeys.grid_dateFilter_after.tr(),
      DateFilterConditionPB.DateOnOrBefore =>
        LocaleKeys.grid_dateFilter_onOrBefore.tr(),
      DateFilterConditionPB.DateOnOrAfter =>
        LocaleKeys.grid_dateFilter_onOrAfter.tr(),
      DateFilterConditionPB.DateWithIn =>
        LocaleKeys.grid_dateFilter_between.tr(),
      DateFilterConditionPB.DateIsEmpty =>
        LocaleKeys.grid_dateFilter_empty.tr(),
      DateFilterConditionPB.DateIsNotEmpty =>
        LocaleKeys.grid_dateFilter_notEmpty.tr(),
      _ => "",
    };
  }
}

extension DateTimeChoicechipExtension on DateTime {
  DateTime get considerLocal {
    return DateTime(year, month, day);
  }
}

extension DateTimeDefaultFormatExtension on DateTime? {
  String? get defaultFormat {
    return this != null ? DateFormat('dd/MM/yyyy').format(this!) : null;
  }
}
