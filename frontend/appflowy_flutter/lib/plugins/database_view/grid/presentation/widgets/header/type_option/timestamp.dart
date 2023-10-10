import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_parser.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/common/type_option_separator.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle.dart';
import 'package:appflowy/workspace/presentation/widgets/toggle/toggle_style.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/timestamp_entities.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:protobuf/protobuf.dart';

import 'builder.dart';
import 'date.dart';

class TimestampTypeOptionEditor extends StatelessWidget {
  final FieldPB field;
  final TimestampTypeOptionPB typeOption;
  final TypeOptionDataCallback onTypeOptionUpdated;
  final PopoverMutex popoverMutex;

  TimestampTypeOptionEditor({
    required this.field,
    required TimestampTypeOptionParser parser,
    required this.onTypeOptionUpdated,
    required this.popoverMutex,
    super.key,
  }) : typeOption = parser.fromBuffer(field.typeOptionData);

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      const TypeOptionSeparator(),
      _renderDateFormatButton(context, typeOption.dateFormat),
      _renderTimeFormatButton(context, typeOption.timeFormat),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: IncludeTimeButton(
          onChanged: (value) => _updateTypeOption(includeTime: !value),
          value: typeOption.includeTime,
        ),
      ),
    ];

    return ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (context, index) {
        if (index == 0) {
          return const SizedBox();
        } else {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        }
      },
      itemCount: children.length,
      itemBuilder: (BuildContext context, int index) => children[index],
    );
  }

  Widget _renderDateFormatButton(
    BuildContext context,
    DateFormatPB dataFormat,
  ) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(8, 0),
      constraints: BoxConstraints.loose(const Size(460, 440)),
      popupBuilder: (popoverContext) {
        return DateFormatList(
          selectedFormat: dataFormat,
          onSelected: (format) {
            _updateTypeOption(dateFormat: format);
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
    BuildContext context,
    TimeFormatPB timeFormat,
  ) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(8, 0),
      constraints: BoxConstraints.loose(const Size(460, 440)),
      popupBuilder: (BuildContext popoverContext) {
        return TimeFormatList(
          selectedFormat: timeFormat,
          onSelected: (format) {
            _updateTypeOption(timeFormat: format);
            PopoverContainer.of(popoverContext).close();
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: TimeFormatButton(timeFormat: timeFormat),
      ),
    );
  }

  void _updateTypeOption({
    DateFormatPB? dateFormat,
    TimeFormatPB? timeFormat,
    bool? includeTime,
  }) {
    typeOption.freeze();
    final newTypeOption = typeOption.rebuild((typeOption) {
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
    onTypeOptionUpdated.call(newTypeOption.writeToBuffer());
  }
}

class IncludeTimeButton extends StatelessWidget {
  final bool value;
  final Function(bool value) onChanged;
  const IncludeTimeButton({
    super.key,
    required this.onChanged,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: Padding(
        padding: GridSize.typeOptionContentInsets,
        child: Row(
          children: [
            FlowySvg(
              FlowySvgs.clock_alarm_s,
              color: Theme.of(context).iconTheme.color,
            ),
            const HSpace(6),
            FlowyText.medium(LocaleKeys.grid_field_includeTime.tr()),
            const Spacer(),
            Toggle(
              value: value,
              onChanged: onChanged,
              style: ToggleStyle.big,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }
}
