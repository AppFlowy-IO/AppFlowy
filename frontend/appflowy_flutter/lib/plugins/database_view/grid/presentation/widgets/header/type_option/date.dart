import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_parser.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:easy_localization/easy_localization.dart' hide DateFormat;
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:protobuf/protobuf.dart';

import '../../../layout/sizes.dart';
import 'builder.dart';

class DateTimeTypeOptionEditor extends StatelessWidget {
  final FieldPB field;
  final DateTypeOptionPB typeOption;
  final TypeOptionDataCallback onTypeOptionUpdated;
  final PopoverMutex popoverMutex;

  DateTimeTypeOptionEditor({
    required this.field,
    required this.onTypeOptionUpdated,
    required DateTypeOptionParser parser,
    required this.popoverMutex,
    super.key,
  }) : typeOption = parser.fromBuffer(field.typeOptionData);

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      _renderDateFormatButton(context, typeOption.dateFormat),
      _renderTimeFormatButton(context, typeOption.timeFormat),
    ];

    return ListView.separated(
      shrinkWrap: true,
      separatorBuilder: (context, index) =>
          VSpace(GridSize.typeOptionSeparatorHeight),
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
  }) {
    typeOption.freeze();
    final newTypeOption = typeOption.rebuild((typeOption) {
      if (dateFormat != null) {
        typeOption.dateFormat = dateFormat;
      }
      if (timeFormat != null) {
        typeOption.timeFormat = timeFormat;
      }
    });
    onTypeOptionUpdated.call(newTypeOption.writeToBuffer());
  }
}

class DateFormatButton extends StatelessWidget {
  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  const DateFormatButton({
    this.onTap,
    this.onHover,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_field_dateFormat.tr()),
        onTap: onTap,
        onHover: onHover,
        rightIcon: const FlowySvg(FlowySvgs.more_s),
      ),
    );
  }
}

class TimeFormatButton extends StatelessWidget {
  final TimeFormatPB timeFormat;
  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  const TimeFormatButton({
    required this.timeFormat,
    this.onTap,
    this.onHover,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_field_timeFormat.tr()),
        onTap: onTap,
        onHover: onHover,
        rightIcon: const FlowySvg(FlowySvgs.more_s),
      ),
    );
  }
}

class DateFormatList extends StatelessWidget {
  final DateFormatPB selectedFormat;
  final Function(DateFormatPB format) onSelected;
  const DateFormatList({
    required this.selectedFormat,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = DateFormatPB.values.map((format) {
      return DateFormatCell(
        dateFormat: format,
        onSelected: onSelected,
        isSelected: selectedFormat == format,
      );
    }).toList();

    return SizedBox(
      width: 180,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        itemCount: cells.length,
        itemBuilder: (BuildContext context, int index) {
          return cells[index];
        },
      ),
    );
  }
}

class DateFormatCell extends StatelessWidget {
  final bool isSelected;
  final DateFormatPB dateFormat;
  final Function(DateFormatPB format) onSelected;
  const DateFormatCell({
    required this.dateFormat,
    required this.onSelected,
    required this.isSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? checkmark;
    if (isSelected) {
      checkmark = const FlowySvg(FlowySvgs.check_s);
    }

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(dateFormat.title()),
        rightIcon: checkmark,
        onTap: () => onSelected(dateFormat),
      ),
    );
  }
}

extension DateFormatExtension on DateFormatPB {
  String title() {
    switch (this) {
      case DateFormatPB.Friendly:
        return LocaleKeys.grid_field_dateFormatFriendly.tr();
      case DateFormatPB.ISO:
        return LocaleKeys.grid_field_dateFormatISO.tr();
      case DateFormatPB.Local:
        return LocaleKeys.grid_field_dateFormatLocal.tr();
      case DateFormatPB.US:
        return LocaleKeys.grid_field_dateFormatUS.tr();
      case DateFormatPB.DayMonthYear:
        return LocaleKeys.grid_field_dateFormatDayMonthYear.tr();
      default:
        throw UnimplementedError;
    }
  }
}

class TimeFormatList extends StatelessWidget {
  final TimeFormatPB selectedFormat;
  final Function(TimeFormatPB format) onSelected;
  const TimeFormatList({
    required this.selectedFormat,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = TimeFormatPB.values.map((format) {
      return TimeFormatCell(
        isSelected: format == selectedFormat,
        timeFormat: format,
        onSelected: onSelected,
      );
    }).toList();

    return SizedBox(
      width: 120,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        itemCount: cells.length,
        itemBuilder: (BuildContext context, int index) {
          return cells[index];
        },
      ),
    );
  }
}

class TimeFormatCell extends StatelessWidget {
  final TimeFormatPB timeFormat;
  final bool isSelected;
  final Function(TimeFormatPB format) onSelected;
  const TimeFormatCell({
    required this.timeFormat,
    required this.onSelected,
    required this.isSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? checkmark;
    if (isSelected) {
      checkmark = const FlowySvg(FlowySvgs.check_s);
    }

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(timeFormat.title()),
        rightIcon: checkmark,
        onTap: () => onSelected(timeFormat),
      ),
    );
  }
}

extension TimeFormatExtension on TimeFormatPB {
  String title() {
    switch (this) {
      case TimeFormatPB.TwelveHour:
        return LocaleKeys.grid_field_timeFormatTwelveHour.tr();
      case TimeFormatPB.TwentyFourHour:
        return LocaleKeys.grid_field_timeFormatTwentyFourHour.tr();
      default:
        throw UnimplementedError;
    }
  }
}
