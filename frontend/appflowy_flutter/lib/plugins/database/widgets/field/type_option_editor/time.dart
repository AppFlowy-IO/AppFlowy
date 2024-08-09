import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:protobuf/protobuf.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../grid/presentation/layout/sizes.dart';
import 'builder.dart';
import 'util.dart';

class TimeTypeOptionEditorFactory implements TypeOptionEditorFactory {
  const TimeTypeOptionEditorFactory();

  @override
  Widget? build({
    required BuildContext context,
    required String viewId,
    required FieldPB field,
    required PopoverMutex popoverMutex,
    required TypeOptionDataCallback onTypeOptionUpdated,
  }) {
    final typeOption = _parseTypeOptionData(field.typeOptionData);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _renderTimeTypeButton(
          typeOption,
          popoverMutex,
          onTypeOptionUpdated,
        ),
        VSpace(GridSize.typeOptionSeparatorHeight),
        _renderTimePrecisionButton(
          typeOption,
          popoverMutex,
          onTypeOptionUpdated,
        ),
      ],
    );
  }

  Widget _renderTimeTypeButton(
    TimeTypeOptionPB typeOption,
    PopoverMutex popoverMutex,
    TypeOptionDataCallback onTypeOptionUpdated,
  ) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(8, 0),
      constraints: BoxConstraints.loose(const Size(460, 440)),
      popupBuilder: (popoverContext) {
        return TypeOptionList(
          options: {for (final v in TimeTypePB.values) v.title(): v},
          selectedOption: typeOption.timeType,
          onSelected: (timeType) {
            final newTypeOption =
                _updateTypeOption(typeOption: typeOption, timeType: timeType);
            onTypeOptionUpdated(newTypeOption.writeToBuffer());
            PopoverContainer.of(popoverContext).close();
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: TypeOptionButton(text: LocaleKeys.grid_field_timeType.tr()),
      ),
    );
  }

  Widget _renderTimePrecisionButton(
    TimeTypeOptionPB typeOption,
    PopoverMutex popoverMutex,
    TypeOptionDataCallback onTypeOptionUpdated,
  ) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(8, 0),
      constraints: BoxConstraints.loose(const Size(460, 440)),
      popupBuilder: (BuildContext popoverContext) {
        return TypeOptionList(
          options: {for (final v in TimePrecisionPB.values) v.title(): v},
          selectedOption: typeOption.precision,
          onSelected: (precision) {
            final newTypeOption =
                _updateTypeOption(typeOption: typeOption, precision: precision);
            onTypeOptionUpdated(newTypeOption.writeToBuffer());
            PopoverContainer.of(popoverContext).close();
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: TypeOptionButton(text: LocaleKeys.grid_field_timePrecision.tr()),
      ),
    );
  }

  TimeTypeOptionPB _parseTypeOptionData(List<int> data) {
    return TimeTypeOptionDataParser().fromBuffer(data);
  }

  TimeTypeOptionPB _updateTypeOption({
    required TimeTypeOptionPB typeOption,
    TimeTypePB? timeType,
    TimePrecisionPB? precision,
  }) {
    typeOption.freeze();
    return typeOption.rebuild((typeOption) {
      if (timeType != null) {
        typeOption.timeType = timeType;
      }

      if (precision != null) {
        typeOption.precision = precision;
      }
    });
  }
}

extension TimeTypeExtension on TimeTypePB {
  String title() {
    switch (this) {
      case TimeTypePB.PlainTime:
        return LocaleKeys.grid_field_timeTypePlainTime.tr();
      case TimeTypePB.Timer:
        return LocaleKeys.grid_field_timeTypeTimer.tr();
      case TimeTypePB.Stopwatch:
        return LocaleKeys.grid_field_timeTypeStopwatch.tr();
      default:
        throw UnimplementedError;
    }
  }
}

extension TimePrecisionExtension on TimePrecisionPB {
  String title() {
    switch (this) {
      case TimePrecisionPB.Seconds:
        return LocaleKeys.grid_field_timePrecisionSeconds.tr();
      case TimePrecisionPB.Minutes:
        return LocaleKeys.grid_field_timePrecisionMinutes.tr();
      default:
        throw UnimplementedError;
    }
  }
}
