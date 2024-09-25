import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:appflowy/workspace/presentation/widgets/date_picker/appflowy_date_picker.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../condition_button.dart';
import '../disclosure_button.dart';

import 'choicechip.dart';

class DateFilterChoicechip extends StatelessWidget {
  const DateFilterChoicechip({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(275, 120)),
      direction: PopoverDirection.bottomWithLeftAligned,
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: DateFilterEditor(filterId: filterId),
        );
      },
      child: SingleFilterBlocSelector<DateTimeFilter>(
        filterId: filterId,
        builder: (context, filter, field) {
          return ChoiceChipButton(
            fieldInfo: field,
            filterDesc: filter.getDescription(field),
          );
        },
      ),
    );
  }
}

class DateFilterEditor extends StatefulWidget {
  const DateFilterEditor({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  State<DateFilterEditor> createState() => _DateFilterEditorState();
}

class _DateFilterEditorState extends State<DateFilterEditor> {
  final popoverMutex = PopoverMutex();
  final popooverController = PopoverController();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleFilterBlocSelector<DateTimeFilter>(
      filterId: widget.filterId,
      builder: (context, filter, field) {
        final List<Widget> children = [
          _buildFilterPanel(filter, field),
          if (![
            DateFilterConditionPB.DateStartIsEmpty,
            DateFilterConditionPB.DateStartIsNotEmpty,
            DateFilterConditionPB.DateEndIsEmpty,
            DateFilterConditionPB.DateStartIsNotEmpty,
          ].contains(filter.condition)) ...[
            const VSpace(4),
            _buildFilterContentField(filter),
          ],
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: IntrinsicHeight(child: Column(children: children)),
        );
      },
    );
  }

  Widget _buildFilterPanel(
    DateTimeFilter filter,
    FieldInfo field,
  ) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: DateFilterIsStartList(
              filter: filter,
              popoverMutex: popoverMutex,
              onChangeIsStart: (isStart) {
                final newFilter = filter.copyWithCondition(
                  isStart: isStart,
                  condition: filter.condition.toCondition(),
                );
                context
                    .read<FilterEditorBloc>()
                    .add(FilterEditorEvent.updateFilter(newFilter));
              },
            ),
          ),
          const HSpace(4),
          Expanded(
            child: DateFilterConditionList(
              filter: filter,
              popoverMutex: popoverMutex,
              onCondition: (condition) {
                final newFilter = filter.copyWithCondition(
                  isStart: filter.condition.isStart,
                  condition: condition,
                );
                context
                    .read<FilterEditorBloc>()
                    .add(FilterEditorEvent.updateFilter(newFilter));
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
                      .read<FilterEditorBloc>()
                      .add(FilterEditorEvent.deleteFilter(filter.filterId));
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContentField(DateTimeFilter filter) {
    final isRange =
        filter.condition == DateFilterConditionPB.DateStartsBetween ||
            filter.condition == DateFilterConditionPB.DateEndsBetween;
    String? text;

    if (isRange) {
      text =
          "${filter.start?.defaultFormat ?? ""} - ${filter.end?.defaultFormat ?? ""}";
      text = text == " - " ? null : text;
    } else {
      text = filter.timestamp.defaultFormat;
    }

    return AppFlowyPopover(
      controller: popooverController,
      triggerActions: PopoverTriggerFlags.none,
      direction: PopoverDirection.bottomWithLeftAligned,
      constraints: BoxConstraints.loose(const Size(260, 620)),
      offset: const Offset(0, 4),
      margin: EdgeInsets.zero,
      mutex: popoverMutex,
      child: FlowyButton(
        decoration: BoxDecoration(
          border: Border.fromBorderSide(
            BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          borderRadius: Corners.s6Border,
        ),
        onTap: popooverController.show,
        text: FlowyText(
          text ?? "",
          overflow: TextOverflow.ellipsis,
        ),
      ),
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: SingleFilterBlocSelector<DateTimeFilter>(
            filterId: widget.filterId,
            builder: (context, filter, field) {
              return AppFlowyDatePicker(
                isRange: isRange,
                timeHintText: LocaleKeys.grid_field_selectTime.tr(),
                includeTime: false,
                dateFormat: DateFormatPB.Friendly,
                timeFormat: TimeFormatPB.TwentyFourHour,
                selectedDay: isRange ? filter.start : filter.timestamp,
                startDay: isRange ? filter.start : null,
                endDay: isRange ? filter.end : null,
                enableReminder: false,
                onDaySelected: (selectedDay, _) {
                  final newFilter = isRange
                      ? filter.copyWithRange(start: selectedDay, end: null)
                      : filter.copyWithTimestamp(timestamp: selectedDay);
                  context
                      .read<FilterEditorBloc>()
                      .add(FilterEditorEvent.updateFilter(newFilter));
                  if (isRange) {
                    popooverController.close();
                  }
                },
                onRangeSelected: (start, end, _) {
                  final newFilter = filter.copyWithRange(
                    start: start,
                    end: end,
                  );
                  context
                      .read<FilterEditorBloc>()
                      .add(FilterEditorEvent.updateFilter(newFilter));
                },
              );
            },
          ),
        );
      },
    );
  }
}

class DateFilterIsStartList extends StatelessWidget {
  const DateFilterIsStartList({
    super.key,
    required this.filter,
    required this.popoverMutex,
    required this.onChangeIsStart,
  });

  final DateTimeFilter filter;
  final PopoverMutex popoverMutex;
  final Function(bool isStart) onChangeIsStart;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<_IsStartWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: [
        _IsStartWrapper(
          true,
          filter.condition.isStart,
        ),
        _IsStartWrapper(
          false,
          !filter.condition.isStart,
        ),
      ],
      buildChild: (controller) {
        return ConditionButton(
          conditionName: filter.condition.isStart
              ? LocaleKeys.grid_dateFilter_startDate.tr()
              : LocaleKeys.grid_dateFilter_endDate.tr(),
          onTap: () => controller.show(),
        );
      },
      onSelected: (action, controller) {
        onChangeIsStart(action.inner);
        controller.close();
      },
    );
  }
}

class _IsStartWrapper extends ActionCell {
  _IsStartWrapper(this.inner, this.isSelected);

  final bool inner;
  final bool isSelected;

  @override
  Widget? rightIcon(Color iconColor) =>
      isSelected ? const FlowySvg(FlowySvgs.check_s) : null;

  @override
  String get name => inner
      ? LocaleKeys.grid_dateFilter_startDate.tr()
      : LocaleKeys.grid_dateFilter_endDate.tr();
}

class DateFilterConditionList extends StatelessWidget {
  const DateFilterConditionList({
    super.key,
    required this.filter,
    required this.popoverMutex,
    required this.onCondition,
  });

  final DateTimeFilter filter;
  final PopoverMutex popoverMutex;
  final Function(DateTimeFilterCondition) onCondition;

  @override
  Widget build(BuildContext context) {
    return PopoverActionList<ConditionWrapper>(
      asBarrier: true,
      mutex: popoverMutex,
      direction: PopoverDirection.bottomWithCenterAligned,
      actions: DateTimeFilterCondition.values
          .map(
            (action) => ConditionWrapper(
              action,
              filter.condition.toCondition() == action,
            ),
          )
          .toList(),
      buildChild: (controller) {
        return ConditionButton(
          conditionName: filter.condition.toCondition().filterName,
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

  final DateTimeFilterCondition inner;
  final bool isSelected;

  @override
  Widget? rightIcon(Color iconColor) =>
      isSelected ? const FlowySvg(FlowySvgs.check_s) : null;

  @override
  String get name => inner.filterName;
}

extension DateFilterConditionPBExtension on DateFilterConditionPB {
  bool get isStart {
    return switch (this) {
      DateFilterConditionPB.DateStartsOn ||
      DateFilterConditionPB.DateStartsBefore ||
      DateFilterConditionPB.DateStartsAfter ||
      DateFilterConditionPB.DateStartsOnOrBefore ||
      DateFilterConditionPB.DateStartsOnOrAfter ||
      DateFilterConditionPB.DateStartsBetween ||
      DateFilterConditionPB.DateStartIsEmpty ||
      DateFilterConditionPB.DateStartIsNotEmpty =>
        true,
      _ => false
    };
  }

  DateTimeFilterCondition toCondition() {
    return switch (this) {
      DateFilterConditionPB.DateStartsOn ||
      DateFilterConditionPB.DateEndsOn =>
        DateTimeFilterCondition.on,
      DateFilterConditionPB.DateStartsBefore ||
      DateFilterConditionPB.DateEndsBefore =>
        DateTimeFilterCondition.before,
      DateFilterConditionPB.DateStartsAfter ||
      DateFilterConditionPB.DateEndsAfter =>
        DateTimeFilterCondition.after,
      DateFilterConditionPB.DateStartsOnOrBefore ||
      DateFilterConditionPB.DateEndsOnOrBefore =>
        DateTimeFilterCondition.onOrBefore,
      DateFilterConditionPB.DateStartsOnOrAfter ||
      DateFilterConditionPB.DateEndsOnOrAfter =>
        DateTimeFilterCondition.onOrAfter,
      DateFilterConditionPB.DateStartsBetween ||
      DateFilterConditionPB.DateEndsBetween =>
        DateTimeFilterCondition.between,
      DateFilterConditionPB.DateStartIsEmpty ||
      DateFilterConditionPB.DateStartIsEmpty =>
        DateTimeFilterCondition.isEmpty,
      DateFilterConditionPB.DateStartIsNotEmpty ||
      DateFilterConditionPB.DateStartIsNotEmpty =>
        DateTimeFilterCondition.isNotEmpty,
      _ => throw ArgumentError(),
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
