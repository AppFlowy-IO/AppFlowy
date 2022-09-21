import 'package:app_flowy/plugins/grid/application/field/type_option/date_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:easy_localization/easy_localization.dart' hide DateFormat;
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option_entities.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import '../../../layout/sizes.dart';
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
          return Column(children: [
            _renderDateFormatButton(context, state.typeOption.dateFormat),
            _renderTimeFormatButton(context, state.typeOption.timeFormat),
            const _IncludeTimeButton(),
          ]);
        },
      ),
    );
  }

  Widget _renderDateFormatButton(BuildContext context, DateFormat dataFormat) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(20, 0),
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
      child: const DateFormatButton(),
    );
  }

  Widget _renderTimeFormatButton(BuildContext context, TimeFormat timeFormat) {
    return AppFlowyPopover(
      mutex: popoverMutex,
      asBarrier: true,
      triggerActions: PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
      offset: const Offset(20, 0),
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
      child: TimeFormatButton(timeFormat: timeFormat),
    );
  }
}

class DateFormatButton extends StatelessWidget {
  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  const DateFormatButton({this.onTap, this.onHover, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_field_dateFormat.tr(),
            fontSize: 12),
        margin: GridSize.typeOptionContentInsets,
        hoverColor: theme.hover,
        onTap: onTap,
        onHover: onHover,
        rightIcon: svgWidget("grid/more", color: theme.iconColor),
      ),
    );
  }
}

class TimeFormatButton extends StatelessWidget {
  final TimeFormat timeFormat;
  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  const TimeFormatButton(
      {required this.timeFormat, this.onTap, this.onHover, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_field_timeFormat.tr(),
            fontSize: 12),
        margin: GridSize.typeOptionContentInsets,
        hoverColor: theme.hover,
        onTap: onTap,
        onHover: onHover,
        rightIcon: svgWidget("grid/more", color: theme.iconColor),
      ),
    );
  }
}

class _IncludeTimeButton extends StatelessWidget {
  const _IncludeTimeButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocSelector<DateTypeOptionBloc, DateTypeOptionState, bool>(
      selector: (state) => state.typeOption.includeTime,
      builder: (context, includeTime) {
        return SizedBox(
          height: GridSize.typeOptionItemHeight,
          child: Padding(
            padding: GridSize.typeOptionContentInsets,
            child: Row(
              children: [
                FlowyText.medium(LocaleKeys.grid_field_includeTime.tr(),
                    fontSize: 12),
                const Spacer(),
                Switch(
                  value: includeTime,
                  onChanged: (newValue) {
                    context
                        .read<DateTypeOptionBloc>()
                        .add(DateTypeOptionEvent.includeTime(newValue));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DateFormatList extends StatelessWidget {
  final DateFormat selectedFormat;
  final Function(DateFormat format) onSelected;
  const DateFormatList(
      {required this.selectedFormat, required this.onSelected, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = DateFormat.values.map((format) {
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
  final DateFormat dateFormat;
  final Function(DateFormat format) onSelected;
  const DateFormatCell({
    required this.dateFormat,
    required this.onSelected,
    required this.isSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    Widget? checkmark;
    if (isSelected) {
      checkmark = svgWidget("grid/checkmark");
    }

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(dateFormat.title(), fontSize: 12),
        hoverColor: theme.hover,
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cells = TimeFormat.values.map((format) {
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
  final TimeFormat timeFormat;
  final bool isSelected;
  final Function(TimeFormat format) onSelected;
  const TimeFormatCell({
    required this.timeFormat,
    required this.onSelected,
    required this.isSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    Widget? checkmark;
    if (isSelected) {
      checkmark = svgWidget("grid/checkmark");
    }

    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(timeFormat.title(), fontSize: 12),
        hoverColor: theme.hover,
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
