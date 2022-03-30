import 'package:app_flowy/startup/startup.dart';
import 'package:app_flowy/workspace/application/grid/field/type_option/date_bloc.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:app_flowy/workspace/presentation/plugins/grid/src/widgets/header/field_tyep_switcher.dart';
import 'package:easy_localization/easy_localization.dart' hide DateFormat;
import 'package:app_flowy/generated/locale_keys.g.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/date_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DateTypeOptionBuilder extends TypeOptionBuilder {
  final DateTypeOptionWidget _widget;

  DateTypeOptionBuilder(
    TypeOptionData typeOptionData,
    TypeOptionOverlayDelegate overlayDelegate,
    TypeOptionDataDelegate dataDelegate,
  ) : _widget = DateTypeOptionWidget(
          typeOption: DateTypeOption.fromBuffer(typeOptionData),
          dataDelegate: dataDelegate,
          overlayDelegate: overlayDelegate,
        );

  @override
  Widget? get customWidget => _widget;
}

class DateTypeOptionWidget extends TypeOptionWidget {
  final DateTypeOption typeOption;
  final TypeOptionOverlayDelegate overlayDelegate;
  final TypeOptionDataDelegate dataDelegate;
  const DateTypeOptionWidget({
    required this.typeOption,
    required this.dataDelegate,
    required this.overlayDelegate,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DateTypeOptionBloc>(param1: typeOption),
      child: BlocConsumer<DateTypeOptionBloc, DateTypeOptionState>(
        listener: (context, state) => dataDelegate.didUpdateTypeOptionData(state.typeOption.writeToBuffer()),
        builder: (context, state) {
          return Column(children: [
            _dateFormatButton(context),
            _timeFormatButton(context),
          ]);
        },
      ),
    );
  }

  Widget _dateFormatButton(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_field_dateFormat.tr(), fontSize: 12),
        padding: GridSize.typeOptionContentInsets,
        hoverColor: theme.hover,
        onTap: () {
          final list = DateFormatList(onSelected: (format) {
            context.read<DateTypeOptionBloc>().add(DateTypeOptionEvent.didSelectDateFormat(format));
          });
          overlayDelegate.showOverlay(context, list);
        },
        rightIcon: svg("grid/more", color: theme.iconColor),
      ),
    );
  }

  Widget _timeFormatButton(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(LocaleKeys.grid_field_timeFormat.tr(), fontSize: 12),
        padding: GridSize.typeOptionContentInsets,
        hoverColor: theme.hover,
        onTap: () {
          final list = TimeFormatList(onSelected: (format) {
            context.read<DateTypeOptionBloc>().add(DateTypeOptionEvent.didSelectTimeFormat(format));
          });
          overlayDelegate.showOverlay(context, list);
        },
        rightIcon: svg("grid/more", color: theme.iconColor),
      ),
    );
  }
}

class DateFormatList extends StatelessWidget {
  final Function(DateFormat format) onSelected;
  const DateFormatList({required this.onSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatItems = DateFormat.values.map((format) {
      return DateFormatItem(
          dateFormat: format,
          onSelected: (format) {
            onSelected(format);
            FlowyOverlay.of(context).remove(identifier());
          });
    }).toList();

    return SizedBox(
      width: 180,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        itemCount: formatItems.length,
        itemBuilder: (BuildContext context, int index) {
          return formatItems[index];
        },
      ),
    );
  }

  String identifier() {
    return toString();
  }
}

class DateFormatItem extends StatelessWidget {
  final DateFormat dateFormat;
  final Function(DateFormat format) onSelected;
  const DateFormatItem({required this.dateFormat, required this.onSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(dateFormat.title(), fontSize: 12),
        hoverColor: theme.hover,
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
  final Function(TimeFormat format) onSelected;
  const TimeFormatList({required this.onSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatItems = TimeFormat.values.map((format) {
      return TimeFormatItem(
          timeFormat: format,
          onSelected: (format) {
            onSelected(format);
            FlowyOverlay.of(context).remove(identifier());
          });
    }).toList();

    return SizedBox(
      width: 120,
      child: ListView.separated(
        shrinkWrap: true,
        controller: ScrollController(),
        separatorBuilder: (context, index) {
          return VSpace(GridSize.typeOptionSeparatorHeight);
        },
        itemCount: formatItems.length,
        itemBuilder: (BuildContext context, int index) {
          return formatItems[index];
        },
      ),
    );
  }

  String identifier() {
    return toString();
  }
}

class TimeFormatItem extends StatelessWidget {
  final TimeFormat timeFormat;
  final Function(TimeFormat format) onSelected;
  const TimeFormatItem({required this.timeFormat, required this.onSelected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return SizedBox(
      height: GridSize.typeOptionItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(timeFormat.title(), fontSize: 12),
        hoverColor: theme.hover,
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
