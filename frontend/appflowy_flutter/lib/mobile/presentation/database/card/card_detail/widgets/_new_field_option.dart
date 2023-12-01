import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/_field_options.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/number_format_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/date.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum FieldOptionMode {
  add,
  edit,
}

class FieldOptionResult {
  FieldOptionResult({
    required this.type,
    required this.name,
    this.dateFormate,
    this.includeTime = false,
    this.timeFormat,
    this.numberFormat,
    this.selectOption = const [],
  });

  FieldType type;
  String name;

  // FieldType.Date
  DateFormatPB? dateFormate;
  bool includeTime;
  TimeFormatPB? timeFormat;

  // FieldType.Num
  NumberFormatPB? numberFormat;

  // FieldType.Select
  // FieldType.MultiSelect
  List<String> selectOption;

  // FieldType.Checklist
}

class FieldOption extends StatefulWidget {
  const FieldOption({
    super.key,
    required this.type,
    required this.mode,
  });

  final FieldType type;
  final FieldOptionMode mode;

  @override
  State<FieldOption> createState() => _FieldOptionState();
}

class _FieldOptionState extends State<FieldOption> {
  final controller = TextEditingController();

  late FieldOptionResult result;

  @override
  void initState() {
    super.initState();

    controller.text = widget.type.i18n;

    result = FieldOptionResult(
      type: widget.type,
      name: widget.type.i18n,
    );
  }

  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Column(
        children: [
          const _Divider(),
          _OptionTextField(
            controller: controller,
            type: result.type,
          ),
          const _Divider(),
          _PropertyType(
            type: result.type,
            onSelected: (type) => setState(
              () {
                controller.text = type.i18n;
                result
                  ..type = type
                  ..name = type.i18n;
              },
            ),
          ),
          const _Divider(),
          ..._buildOption(),
          ..._buildOptionActions(),
        ],
      ),
    );
  }

  List<Widget> _buildOption() {
    switch (result.type) {
      case FieldType.RichText:
        return [
          const _TextOption(),
        ];
      case FieldType.URL:
        return [
          const _URLOption(),
        ];
      case FieldType.Checkbox:
        return [
          const _CheckboxOption(),
        ];
      case FieldType.Number:
        return [
          _NumberOption(
            selectedFormat: result.numberFormat ?? NumberFormatPB.Num,
            onSelected: (format) => result.numberFormat = format,
          ),
        ];
      case FieldType.DateTime:
        return [
          _DateOption(
            selectedFormat: result.dateFormate ?? DateFormatPB.Local,
            onSelected: (format) => result.dateFormate = format,
          ),
          const _Divider(),
          _TimeOption(
            includeTime: result.includeTime,
            selectedFormat: result.timeFormat ?? TimeFormatPB.TwelveHour,
            onSelected: (includeTime, format) => result
              ..includeTime = includeTime
              ..timeFormat = format,
          ),
        ];
      default:
        return [];
    }
  }

  List<Widget> _buildOptionActions() {
    return switch (widget.mode) {
      FieldOptionMode.add => [],
      FieldOptionMode.edit => [
          FlowyOptionTile.text(
            text: LocaleKeys.button_delete.tr(),
            leftIcon: const FlowySvg(FlowySvgs.delete_s),
          ),
          FlowyOptionTile.text(
            showTopBorder: false,
            text: LocaleKeys.button_duplicate.tr(),
            leftIcon: const FlowySvg(FlowySvgs.copy_s),
          ),
          FlowyOptionTile.text(
            showTopBorder: false,
            text: LocaleKeys.grid_field_hide.tr(),
            leftIcon: const FlowySvg(FlowySvgs.hide_s),
          ),
        ]
    };
  }
}

class _OptionTextField extends StatelessWidget {
  const _OptionTextField({
    required this.controller,
    required this.type,
  });

  final TextEditingController controller;
  final FieldType type;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.textField(
      controller: controller,
      textFieldPadding: const EdgeInsets.symmetric(horizontal: 12.0),
      leftIcon: Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: FlowySvg(
          type.svgData,
          size: const Size.square(36.0),
          blendMode: null,
        ),
      ),
    );
  }
}

class _PropertyType extends StatelessWidget {
  const _PropertyType({
    required this.type,
    required this.onSelected,
  });

  final FieldType type;
  final void Function(FieldType type) onSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(
      text: LocaleKeys.grid_field_propertyType.tr(),
      leading: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FlowyText(
            type.i18n,
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
      onTap: () {
        showMobileBottomSheet(
          context,
          padding: EdgeInsets.zero,
          builder: (context) {
            return DraggableScrollableSheet(
              expand: false,
              snap: true,
              initialChildSize: 0.7,
              minChildSize: 0.7,
              builder: (context, controller) => FieldOptions(
                scrollController: controller,
                onAddField: (type) {
                  onSelected(type);
                  context.pop();
                },
              ),
            );
          },
        );
      },
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

class _CheckboxOption extends StatelessWidget {
  const _CheckboxOption();

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

class _NumberOption extends StatelessWidget {
  const _NumberOption({
    required this.selectedFormat,
    required this.onSelected,
  });

  final NumberFormatPB selectedFormat;
  final void Function(NumberFormatPB format) onSelected;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.text(
      text: LocaleKeys.grid_field_numberFormat.tr(),
      leading: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FlowyText(
            selectedFormat.title(),
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
      onTap: () {
        showMobileBottomSheet(
          context,
          padding: EdgeInsets.zero,
          builder: (context) {
            return DraggableScrollableSheet(
              expand: false,
              snap: true,
              initialChildSize: 0.6,
              minChildSize: 0.6,
              builder: (context, scrollController) => _NumberFormatList(
                scrollController: scrollController,
                selectedFormat: selectedFormat,
                onSelected: onSelected,
              ),
            );
          },
        );
      },
    );
  }
}

class _NumberFormatList extends StatelessWidget {
  const _NumberFormatList({
    this.scrollController,
    required this.selectedFormat,
    required this.onSelected,
  });

  final NumberFormatPB selectedFormat;
  final ScrollController? scrollController;
  final void Function(NumberFormatPB format) onSelected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      children: NumberFormatPB.values
          .mapIndexed(
            (index, element) => FlowyOptionTile.checkbox(
              text: element.title(),
              isSelected: selectedFormat == element,
              showTopBorder: index == 0,
              onTap: () => onSelected(element),
            ),
          )
          .toList(),
    );
  }
}
