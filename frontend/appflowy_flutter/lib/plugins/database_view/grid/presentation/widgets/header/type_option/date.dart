import 'package:appflowy/plugins/database_view/application/field/type_option/date_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/date_entities.pbenum.dart';
import 'package:easy_localization/easy_localization.dart' hide DateFormat;
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import '../../../layout/sizes.dart';
import '../../common/type_option_separator.dart';
import '../field_type_option_editor.dart';
import 'builder.dart';

class DateTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  final DateTypeOptionWidget _widget;

  DateTypeOptionWidgetBuilder(
    DateTypeOptionContext typeOptionContext,
    PopoverMutex popoverMutex,
  ) : _widget = DateTypeOptionWidget(
          typeOptionContext: typeOptionContext,
          popoverMutex: popoverMutex,
        );

  @override
  Widget? build(BuildContext context) {
    return _widget;
  }
}

class DateTypeOptionWidget extends TypeOptionWidget {
  final DateTypeOptionContext typeOptionContext;
  final PopoverMutex popoverMutex;
  const DateTypeOptionWidget({
    required this.typeOptionContext,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DateTypeOptionBloc(typeOptionContext: typeOptionContext),
      child: BlocConsumer<DateTypeOptionBloc, DateTypeOptionState>(
        listener: (context, state) =>
            typeOptionContext.typeOption = state.typeOption,
        builder: (context, state) {
          final List<Widget> children = [
            const TypeOptionSeparator(),
            _renderDateFormatButton(context, state.typeOption.dateFormat),
            _renderTimeFormatButton(context, state.typeOption.timeFormat),
          ];

          return ListView.separated(
            shrinkWrap: true,
            controller: ScrollController(),
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
        },
      ),
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
            context
                .read<DateTypeOptionBloc>()
                .add(DateTypeOptionEvent.didSelectDateFormat(format));
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
            context
                .read<DateTypeOptionBloc>()
                .add(DateTypeOptionEvent.didSelectTimeFormat(format));
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
}

class DateFormatButton extends StatelessWidget {
  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  const DateFormatButton({
    this.onTap,
    this.onHover,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_field_dateFormat.tr()),
        onTap: onTap,
        onHover: onHover,
        rightIcon: const FlowySvg(name: 'grid/more'),
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
        rightIcon: const FlowySvg(name: 'grid/more'),
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
      checkmark = const FlowySvg(name: 'grid/checkmark');
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
      checkmark = const FlowySvg(name: 'grid/checkmark');
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
