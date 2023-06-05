import 'package:appflowy/plugins/database_view/application/field/type_option/date_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:easy_localization/easy_localization.dart' hide DateFormat;
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:appflowy_backend/protobuf/flowy-database/date_type_option_entities.pb.dart';
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
    final DateTypeOptionContext typeOptionContext,
    final PopoverMutex popoverMutex,
  ) : _widget = DateTypeOptionWidget(
          typeOptionContext: typeOptionContext,
          popoverMutex: popoverMutex,
        );

  @override
  Widget? build(final BuildContext context) {
    return _widget;
  }
}

class DateTypeOptionWidget extends TypeOptionWidget {
  final DateTypeOptionContext typeOptionContext;
  final PopoverMutex popoverMutex;
  const DateTypeOptionWidget({
    required this.typeOptionContext,
    required this.popoverMutex,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return BlocProvider(
      create: (final context) =>
          DateTypeOptionBloc(typeOptionContext: typeOptionContext),
      child: BlocConsumer<DateTypeOptionBloc, DateTypeOptionState>(
        listener: (final context, final state) =>
            typeOptionContext.typeOption = state.typeOption,
        builder: (final context, final state) {
          final List<Widget> children = [
            const TypeOptionSeparator(),
            _renderDateFormatButton(context, state.typeOption.dateFormat),
            _renderTimeFormatButton(context, state.typeOption.timeFormat),
          ];

          return ListView.separated(
            shrinkWrap: true,
            controller: ScrollController(),
            separatorBuilder: (final context, final index) {
              if (index == 0) {
                return const SizedBox();
              } else {
                return VSpace(GridSize.typeOptionSeparatorHeight);
              }
            },
            itemCount: children.length,
            itemBuilder: (final BuildContext context, final int index) => children[index],
          );
        },
      ),
    );
  }

  Widget _renderDateFormatButton(final BuildContext context, final DateFormat dataFormat) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(8, 0),
      constraints: BoxConstraints.loose(const Size(460, 440)),
      popupBuilder: (final popoverContext) {
        return DateFormatList(
          selectedFormat: dataFormat,
          onSelected: (final format) {
            context
                .read<DateTypeOptionBloc>()
                .add(DateTypeOptionEvent.didSelectDateFormat(format));
            PopoverContainer.of(popoverContext).close();
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: DateFormatButton(
          buttonMargins: GridSize.typeOptionContentInsets,
        ),
      ),
    );
  }

  Widget _renderTimeFormatButton(final BuildContext context, final TimeFormat timeFormat) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(8, 0),
      constraints: BoxConstraints.loose(const Size(460, 440)),
      popupBuilder: (final BuildContext popoverContext) {
        return TimeFormatList(
          selectedFormat: timeFormat,
          onSelected: (final format) {
            context
                .read<DateTypeOptionBloc>()
                .add(DateTypeOptionEvent.didSelectTimeFormat(format));
            PopoverContainer.of(popoverContext).close();
          },
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: TimeFormatButton(
          timeFormat: timeFormat,
          buttonMargins: GridSize.typeOptionContentInsets,
        ),
      ),
    );
  }
}

class DateFormatButton extends StatelessWidget {
  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  final EdgeInsets? buttonMargins;
  const DateFormatButton({
    this.onTap,
    this.onHover,
    this.buttonMargins,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_field_dateFormat.tr()),
        margin: buttonMargins,
        onTap: onTap,
        onHover: onHover,
        rightIcon: const FlowySvg(name: 'grid/more'),
      ),
    );
  }
}

class TimeFormatButton extends StatelessWidget {
  final TimeFormat timeFormat;
  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  final EdgeInsets? buttonMargins;
  const TimeFormatButton({
    required this.timeFormat,
    this.onTap,
    this.onHover,
    this.buttonMargins,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_field_timeFormat.tr()),
        margin: buttonMargins,
        onTap: onTap,
        onHover: onHover,
        rightIcon: const FlowySvg(name: 'grid/more'),
      ),
    );
  }
}

class DateFormatList extends StatelessWidget {
  final DateFormat selectedFormat;
  final Function(DateFormat format) onSelected;
  const DateFormatList({
    required this.selectedFormat,
    required this.onSelected,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final cells = DateFormat.values.map((final format) {
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
        separatorBuilder: (final context, final index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        itemCount: cells.length,
        itemBuilder: (final BuildContext context, final int index) {
          return cells[index];
        },
      ),
    );
  }
}

class DateFormatCell extends StatelessWidget {
  final bool isSelected;
  final DateFormat dateFormat;
  final Function(DateFormat format) onSelected;
  const DateFormatCell({
    required this.dateFormat,
    required this.onSelected,
    required this.isSelected,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
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

extension DateFormatExtension on DateFormat {
  String title() {
    switch (this) {
      case DateFormat.Friendly:
        return LocaleKeys.grid_field_dateFormatFriendly.tr();
      case DateFormat.ISO:
        return LocaleKeys.grid_field_dateFormatISO.tr();
      case DateFormat.Local:
        return LocaleKeys.grid_field_dateFormatLocal.tr();
      case DateFormat.US:
        return LocaleKeys.grid_field_dateFormatUS.tr();
      case DateFormat.DayMonthYear:
        return LocaleKeys.grid_field_dateFormatDayMonthYear.tr();
      default:
        throw UnimplementedError;
    }
  }
}

class TimeFormatList extends StatelessWidget {
  final TimeFormat selectedFormat;
  final Function(TimeFormat format) onSelected;
  const TimeFormatList({
    required this.selectedFormat,
    required this.onSelected,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
    final cells = TimeFormat.values.map((final format) {
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
        separatorBuilder: (final context, final index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        itemCount: cells.length,
        itemBuilder: (final BuildContext context, final int index) {
          return cells[index];
        },
      ),
    );
  }
}

class TimeFormatCell extends StatelessWidget {
  final TimeFormat timeFormat;
  final bool isSelected;
  final Function(TimeFormat format) onSelected;
  const TimeFormatCell({
    required this.timeFormat,
    required this.onSelected,
    required this.isSelected,
    final Key? key,
  }) : super(key: key);

  @override
  Widget build(final BuildContext context) {
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

extension TimeFormatExtension on TimeFormat {
  String title() {
    switch (this) {
      case TimeFormat.TwelveHour:
        return LocaleKeys.grid_field_timeFormatTwelveHour.tr();
      case TimeFormat.TwentyFourHour:
        return LocaleKeys.grid_field_timeFormatTwentyFourHour.tr();
      default:
        throw UnimplementedError;
    }
  }
}
