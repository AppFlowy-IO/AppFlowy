import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/date.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

class NewFieldOption extends StatefulWidget {
  const NewFieldOption({
    super.key,
    required this.type,
  });

  final FieldType type;

  @override
  State<NewFieldOption> createState() => _NewFieldOptionState();
}

class _NewFieldOptionState extends State<NewFieldOption> {
  final controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    controller.text = widget.type.i18n;
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Column(
        children: [
          const _Divider(),
          FlowyOptionTile.textField(
            controller: controller,
            textFieldPadding: const EdgeInsets.symmetric(horizontal: 12.0),
            leftIcon: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: FlowySvg(
                widget.type.svgData,
                size: const Size.square(36.0),
                blendMode: null,
              ),
            ),
          ),
          const _Divider(),
          FlowyOptionTile.text(
            text: LocaleKeys.grid_field_propertyType.tr(),
            leading: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                FlowyText(
                  widget.type.i18n,
                  color: Theme.of(context).hintColor,
                  fontSize: 16.0,
                ),
                const HSpace(4.0),
                FlowySvg(
                  FlowySvgs.arrow_right_s,
                  color: Theme.of(context).hintColor,
                  size: const Size.square(18.0),
                ),
              ],
            ),
          ),
          const _Divider(),
          _DateOption(
            selectedFormat: DateFormatPB.Local,
            onSelected: (_) {},
          ),
          const _Divider(),
          _TimeOption(
            includeTime: false,
            selectedFormat: TimeFormatPB.TwelveHour,
            onSelected: (_, __) {},
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const VSpace(
      24.0,
    );
  }
}

class _TextOption extends StatelessWidget {
  const _TextOption();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _URLOption extends StatelessWidget {
  const _URLOption();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _DateOption extends StatefulWidget {
  const _DateOption({
    required this.selectedFormat,
    required this.onSelected,
  });

  final DateFormatPB selectedFormat;
  final Function(DateFormatPB format) onSelected;

  @override
  State<_DateOption> createState() => _DateOptionState();
}

class _DateOptionState extends State<_DateOption> {
  DateFormatPB selectedFormat = DateFormatPB.Local;

  @override
  void initState() {
    super.initState();

    selectedFormat = widget.selectedFormat;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 6.0,
            horizontal: 16.0,
          ),
          child: FlowyText(
            LocaleKeys.grid_field_dateFormat.tr(),
            fontSize: 16.0,
          ),
        ),
        ...DateFormatPB.values.mapIndexed((index, format) {
          return FlowyOptionTile.checkbox(
            text: format.title(),
            isSelected: selectedFormat == format,
            showTopBorder: index == 0,
            onTap: () {
              widget.onSelected(format);
              setState(() {
                selectedFormat = format;
              });
            },
          );
        }),
      ],
    );
  }
}

class _TimeOption extends StatefulWidget {
  const _TimeOption({
    required this.includeTime,
    required this.selectedFormat,
    required this.onSelected,
  });

  final bool includeTime;
  final TimeFormatPB selectedFormat;
  final Function(bool includeTime, TimeFormatPB format) onSelected;

  @override
  State<_TimeOption> createState() => _TimeOptionState();
}

class _TimeOptionState extends State<_TimeOption> {
  TimeFormatPB selectedFormat = TimeFormatPB.TwelveHour;
  bool includeTime = false;

  @override
  void initState() {
    super.initState();

    selectedFormat = widget.selectedFormat;
    includeTime = widget.includeTime;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 6.0,
            horizontal: 16.0,
          ),
          child: FlowyText(
            LocaleKeys.grid_field_timeFormat.tr(),
            fontSize: 16.0,
          ),
        ),
        FlowyOptionTile.switcher(
          text: LocaleKeys.grid_field_includeTime.tr(),
          isSelected: includeTime,
          onValueChanged: (includeTime) {
            widget.onSelected(includeTime, selectedFormat);
            setState(() {
              this.includeTime = includeTime;
            });
          },
        ),
        if (includeTime)
          ...TimeFormatPB.values.mapIndexed((index, format) {
            return FlowyOptionTile.checkbox(
              text: format.title(),
              isSelected: selectedFormat == format,
              showTopBorder: false,
              onTap: () {
                widget.onSelected(includeTime, format);
                setState(() {
                  selectedFormat = format;
                });
              },
            );
          }),
      ],
    );
  }
}
