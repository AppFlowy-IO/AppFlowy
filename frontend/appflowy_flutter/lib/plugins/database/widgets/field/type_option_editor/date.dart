import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:protobuf/protobuf.dart';

import '../../../grid/presentation/layout/sizes.dart';
import 'builder.dart';
import 'date/date_time_format.dart';

class DateTypeOptionEditorFactory implements TypeOptionEditorFactory {
  const DateTypeOptionEditorFactory();

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
        _renderDateFormatButton(
          typeOption,
          popoverMutex,
          onTypeOptionUpdated,
        ),
        VSpace(GridSize.typeOptionSeparatorHeight),
        _renderTimeFormatButton(
          typeOption,
          popoverMutex,
          onTypeOptionUpdated,
        ),
      ],
    );
  }

  Widget _renderDateFormatButton(
    DateTypeOptionPB typeOption,
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
    DateTypeOptionPB typeOption,
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

  DateTypeOptionPB _parseTypeOptionData(List<int> data) {
    return DateTypeOptionDataParser().fromBuffer(data);
  }

  DateTypeOptionPB _updateTypeOption({
    required DateTypeOptionPB typeOption,
    DateFormatPB? dateFormat,
    TimeFormatPB? timeFormat,
  }) {
    typeOption.freeze();
    return typeOption.rebuild((typeOption) {
      if (dateFormat != null) {
        typeOption.dateFormat = dateFormat;
      }

      if (timeFormat != null) {
        typeOption.timeFormat = timeFormat;
      }
    });
  }
}
