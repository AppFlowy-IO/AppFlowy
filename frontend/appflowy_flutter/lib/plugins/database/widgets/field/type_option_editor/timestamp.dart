import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:protobuf/protobuf.dart';

import 'builder.dart';
import 'date/date_time_format.dart';

class TimestampTypeOptionEditorFactory implements TypeOptionEditorFactory {
  const TimestampTypeOptionEditorFactory();

  @override
  Widget? build({
    required BuildContext context,
    required String viewId,
    required FieldPB field,
    required PopoverMutex popoverMutex,
    required TypeOptionDataCallback onTypeOptionUpdated,
  }) {
    final typeOption = _parseTypeOptionData(field.typeOptionData);

    return SeparatedColumn(
      mainAxisSize: MainAxisSize.min,
      separatorBuilder: () => VSpace(GridSize.typeOptionSeparatorHeight),
      children: [
        _renderDateFormatButton(typeOption, popoverMutex, onTypeOptionUpdated),
        _renderTimeFormatButton(typeOption, popoverMutex, onTypeOptionUpdated),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: IncludeTimeButton(
            onChanged: (value) {
              final newTypeOption = _updateTypeOption(
                typeOption: typeOption,
                includeTime: value,
              );
              onTypeOptionUpdated(newTypeOption.writeToBuffer());
            },
            includeTime: typeOption.includeTime,
          ),
        ),
      ],
    );
  }

  Widget _renderDateFormatButton(
    TimestampTypeOptionPB typeOption,
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
        return DateFormatList(
          selectedFormat: typeOption.dateFormat,
          onSelected: (format) {
            final newTypeOption =
                _updateTypeOption(typeOption: typeOption, dateFormat: format);
            onTypeOptionUpdated(newTypeOption.writeToBuffer());
            PopoverContainer.of(popoverContext).close();
          },
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: DateFormatButton(),
      ),
    );
  }

  Widget _renderTimeFormatButton(
    TimestampTypeOptionPB typeOption,
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
        return TimeFormatList(
          selectedFormat: typeOption.timeFormat,
          onSelected: (format) {
            final newTypeOption =
                _updateTypeOption(typeOption: typeOption, timeFormat: format);
            onTypeOptionUpdated(newTypeOption.writeToBuffer());
            PopoverContainer.of(popoverContext).close();
          },
        );
      },
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: TimeFormatButton(),
      ),
    );
  }

  TimestampTypeOptionPB _parseTypeOptionData(List<int> data) {
    return TimestampTypeOptionDataParser().fromBuffer(data);
  }

  TimestampTypeOptionPB _updateTypeOption({
    required TimestampTypeOptionPB typeOption,
    DateFormatPB? dateFormat,
    TimeFormatPB? timeFormat,
    bool? includeTime,
  }) {
    typeOption.freeze();
    return typeOption.rebuild((typeOption) {
      if (dateFormat != null) {
        typeOption.dateFormat = dateFormat;
      }

      if (timeFormat != null) {
        typeOption.timeFormat = timeFormat;
      }

      if (includeTime != null) {
        typeOption.includeTime = includeTime;
      }
    });
  }
}
