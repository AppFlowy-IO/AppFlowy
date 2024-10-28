import 'dart:math';
import 'dart:typed_data';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/flowy_search_text_field.dart';
import 'package:appflowy/mobile/presentation/base/option_color_list.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/base/drag_handler.dart';
import 'package:appflowy/plugins/database/domain/field_service.dart';
import 'package:appflowy/plugins/database/application/field/type_option/number_format_bloc.dart';
import 'package:appflowy/plugins/database/widgets/field/type_option_editor/date/date_time_format.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy/util/field_type_extension.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/size.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:protobuf/protobuf.dart';

import 'mobile_field_bottom_sheets.dart';

enum FieldOptionMode {
  add,
  edit,
}

class FieldOptionValues {
  FieldOptionValues({
    required this.type,
    required this.name,
    required this.icon,
    this.dateFormat,
    this.timeFormat,
    this.includeTime,
    this.numberFormat,
    this.selectOption = const [],
  });

  factory FieldOptionValues.fromField({required FieldPB field}) {
    final fieldType = field.fieldType;
    final buffer = field.typeOptionData;
    return FieldOptionValues(
      type: fieldType,
      name: field.name,
      icon: field.icon,
      numberFormat: fieldType == FieldType.Number
          ? NumberTypeOptionPB.fromBuffer(buffer).format
          : null,
      dateFormat: switch (fieldType) {
        FieldType.DateTime => DateTypeOptionPB.fromBuffer(buffer).dateFormat,
        FieldType.LastEditedTime ||
        FieldType.CreatedTime =>
          TimestampTypeOptionPB.fromBuffer(buffer).dateFormat,
        _ => null
      },
      timeFormat: switch (fieldType) {
        FieldType.DateTime => DateTypeOptionPB.fromBuffer(buffer).timeFormat,
        FieldType.LastEditedTime ||
        FieldType.CreatedTime =>
          TimestampTypeOptionPB.fromBuffer(buffer).timeFormat,
        _ => null
      },
      includeTime: switch (fieldType) {
        FieldType.LastEditedTime ||
        FieldType.CreatedTime =>
          TimestampTypeOptionPB.fromBuffer(buffer).includeTime,
        _ => null
      },
      selectOption: switch (fieldType) {
        FieldType.SingleSelect =>
          SingleSelectTypeOptionPB.fromBuffer(buffer).options,
        FieldType.MultiSelect =>
          MultiSelectTypeOptionPB.fromBuffer(buffer).options,
        _ => [],
      },
    );
  }

  FieldType type;
  String name;
  String icon;

  // FieldType.DateTime
  // FieldType.LastEditedTime
  // FieldType.CreatedTime
  DateFormatPB? dateFormat;
  TimeFormatPB? timeFormat;

  // FieldType.LastEditedTime
  // FieldType.CreatedTime
  bool? includeTime;

  // FieldType.Number
  NumberFormatPB? numberFormat;

  // FieldType.Select
  // FieldType.MultiSelect
  List<SelectOptionPB> selectOption;

  Future<void> create({
    required String viewId,
    OrderObjectPositionPB? position,
  }) async {
    await FieldBackendService.createField(
      viewId: viewId,
      fieldType: type,
      fieldName: name,
      typeOptionData: getTypeOptionData(),
      position: position,
    );
  }

  Uint8List? getTypeOptionData() {
    switch (type) {
      case FieldType.RichText:
      case FieldType.URL:
      case FieldType.Checkbox:
      case FieldType.Time:
        return null;
      case FieldType.Number:
        return NumberTypeOptionPB(
          format: numberFormat,
        ).writeToBuffer();
      case FieldType.DateTime:
        return DateTypeOptionPB(
          dateFormat: dateFormat,
          timeFormat: timeFormat,
        ).writeToBuffer();
      case FieldType.SingleSelect:
        return SingleSelectTypeOptionPB(
          options: selectOption,
        ).writeToBuffer();
      case FieldType.MultiSelect:
        return MultiSelectTypeOptionPB(
          options: selectOption,
        ).writeToBuffer();
      case FieldType.Checklist:
        return ChecklistTypeOptionPB().writeToBuffer();
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return TimestampTypeOptionPB(
          dateFormat: dateFormat,
          timeFormat: timeFormat,
          includeTime: includeTime,
        ).writeToBuffer();
      case FieldType.Media:
        return MediaTypeOptionPB().writeToBuffer();
      default:
        throw UnimplementedError();
    }
  }
}

enum FieldOptionAction {
  hide,
  show,
  duplicate,
  delete,
}

class MobileFieldEditor extends StatefulWidget {
  const MobileFieldEditor({
    super.key,
    required this.mode,
    required this.defaultValues,
    required this.onOptionValuesChanged,
    this.actions = const [],
    this.onAction,
    this.isPrimary = false,
  });

  final FieldOptionMode mode;
  final FieldOptionValues defaultValues;
  final void Function(FieldOptionValues values) onOptionValuesChanged;

  // only used in edit mode
  final List<FieldOptionAction> actions;
  final void Function(FieldOptionAction action)? onAction;

  // the primary field can't be deleted, duplicated, and changed type
  final bool isPrimary;

  @override
  State<MobileFieldEditor> createState() => _MobileFieldEditorState();
}

class _MobileFieldEditorState extends State<MobileFieldEditor> {
  final controller = TextEditingController();
  bool isFieldNameChanged = false;

  late FieldOptionValues values;

  @override
  void initState() {
    super.initState();
    values = widget.defaultValues;
    controller.text = values.name;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final option = _buildOption();
    return Container(
      color: Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFF7F8FB)
          : const Color(0xFF23262B),
      height: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const _Divider(),
            OptionTextField(
              controller: controller,
              autoFocus: widget.mode == FieldOptionMode.add,
              fieldType: values.type,
              isPrimary: widget.isPrimary,
              onTextChanged: (value) {
                isFieldNameChanged = true;
                _updateOptionValues(name: value);
              },
              onFieldTypeChanged: (type) {
                setState(
                  () {
                    if (widget.mode == FieldOptionMode.add &&
                        !isFieldNameChanged) {
                      controller.text = type.i18n;
                      _updateOptionValues(name: type.i18n);
                    }
                    _updateOptionValues(type: type);
                  },
                );
              },
            ),
            const _Divider(),
            if (!widget.isPrimary) ...[
              _PropertyType(
                type: values.type,
                onSelected: (type) {
                  setState(
                    () {
                      if (widget.mode == FieldOptionMode.add &&
                          !isFieldNameChanged) {
                        controller.text = type.i18n;
                        _updateOptionValues(name: type.i18n);
                      }
                      _updateOptionValues(type: type);
                    },
                  );
                },
              ),
              const _Divider(),
              if (option.isNotEmpty) ...[
                ...option,
                const _Divider(),
              ],
            ],
            ..._buildOptionActions(),
            const _Divider(),
            VSpace(MediaQuery.viewPaddingOf(context).bottom == 0 ? 28.0 : 16.0),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOption() {
    switch (values.type) {
      case FieldType.Number:
        return [
          _NumberOption(
            selectedFormat: values.numberFormat ?? NumberFormatPB.Num,
            onSelected: (format) => setState(
              () => _updateOptionValues(
                numberFormat: format,
              ),
            ),
          ),
        ];
      case FieldType.DateTime:
        return [
          _DateOption(
            selectedFormat: values.dateFormat ?? DateFormatPB.Local,
            onSelected: (format) => _updateOptionValues(
              dateFormat: format,
            ),
          ),
          const _Divider(),
          _TimeOption(
            selectedFormat: values.timeFormat ?? TimeFormatPB.TwelveHour,
            onSelected: (format) => _updateOptionValues(
              timeFormat: format,
            ),
          ),
        ];
      case FieldType.LastEditedTime:
      case FieldType.CreatedTime:
        return [
          _DateOption(
            selectedFormat: values.dateFormat ?? DateFormatPB.Local,
            onSelected: (format) => _updateOptionValues(
              dateFormat: format,
            ),
          ),
          const _Divider(),
          _TimeOption(
            selectedFormat: values.timeFormat ?? TimeFormatPB.TwelveHour,
            onSelected: (format) => _updateOptionValues(
              timeFormat: format,
            ),
          ),
          const _Divider(),
          _IncludeTimeOption(
            includeTime: values.includeTime ?? true,
            onToggle: (includeTime) => _updateOptionValues(
              includeTime: includeTime,
            ),
          ),
        ];
      case FieldType.SingleSelect:
      case FieldType.MultiSelect:
        return [
          _SelectOption(
            mode: widget.mode,
            selectOption: values.selectOption,
            onAddOptions: (options) {
              if (values.selectOption.lastOrNull?.name.isEmpty == true) {
                // ignore the add action if the last one doesn't have a name
                return;
              }
              setState(() {
                _updateOptionValues(
                  selectOption: values.selectOption + options,
                );
              });
            },
            onUpdateOptions: (options) {
              _updateOptionValues(selectOption: options);
            },
          ),
        ];
      default:
        return [];
    }
  }

  List<Widget> _buildOptionActions() {
    if (widget.mode == FieldOptionMode.add || widget.actions.isEmpty) {
      return [];
    }

    return [
      if (widget.actions.contains(FieldOptionAction.hide) && !widget.isPrimary)
        FlowyOptionTile.text(
          text: LocaleKeys.grid_field_hide.tr(),
          leftIcon: const FlowySvg(FlowySvgs.m_field_hide_s),
          onTap: () => widget.onAction?.call(FieldOptionAction.hide),
        ),
      if (widget.actions.contains(FieldOptionAction.show))
        FlowyOptionTile.text(
          text: LocaleKeys.grid_field_show.tr(),
          leftIcon: const FlowySvg(FlowySvgs.show_m, size: Size.square(16)),
          onTap: () => widget.onAction?.call(FieldOptionAction.show),
        ),
      if (widget.actions.contains(FieldOptionAction.duplicate) &&
          !widget.isPrimary)
        FlowyOptionTile.text(
          showTopBorder: false,
          text: LocaleKeys.button_duplicate.tr(),
          leftIcon: const FlowySvg(FlowySvgs.m_field_copy_s),
          onTap: () => widget.onAction?.call(FieldOptionAction.duplicate),
        ),
      if (widget.actions.contains(FieldOptionAction.delete) &&
          !widget.isPrimary)
        FlowyOptionTile.text(
          showTopBorder: false,
          text: LocaleKeys.button_delete.tr(),
          textColor: Theme.of(context).colorScheme.error,
          leftIcon: FlowySvg(
            FlowySvgs.m_delete_s,
            color: Theme.of(context).colorScheme.error,
          ),
          onTap: () => widget.onAction?.call(FieldOptionAction.delete),
        ),
    ];
  }

  void _updateOptionValues({
    FieldType? type,
    String? name,
    DateFormatPB? dateFormat,
    TimeFormatPB? timeFormat,
    bool? includeTime,
    NumberFormatPB? numberFormat,
    List<SelectOptionPB>? selectOption,
  }) {
    if (type != null) {
      values.type = type;
    }
    if (name != null) {
      values.name = name;
    }
    if (dateFormat != null) {
      values.dateFormat = dateFormat;
    }
    if (timeFormat != null) {
      values.timeFormat = timeFormat;
    }
    if (includeTime != null) {
      values.includeTime = includeTime;
    }
    if (numberFormat != null) {
      values.numberFormat = numberFormat;
    }
    if (selectOption != null) {
      values.selectOption = selectOption;
    }

    widget.onOptionValuesChanged(values);
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
      trailing: Row(
        children: [
          FlowySvg(
            type.svgData,
            size: const Size.square(22),
            color: Theme.of(context).hintColor,
          ),
          const HSpace(6.0),
          FlowyText(
            type.i18n,
            color: Theme.of(context).hintColor,
          ),
          const HSpace(4.0),
          FlowySvg(
            FlowySvgs.arrow_right_s,
            color: Theme.of(context).hintColor,
            size: const Size.square(18.0),
          ),
        ],
      ),
      onTap: () async {
        final fieldType = await showFieldTypeGridBottomSheet(
          context,
          title: LocaleKeys.grid_field_editProperty.tr(),
        );
        if (fieldType != null) {
          onSelected(fieldType);
        }
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
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 4.0),
          child: FlowyText(
            LocaleKeys.grid_field_dateFormat.tr().toUpperCase(),
            fontSize: 13,
            color: Theme.of(context).hintColor,
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
    required this.selectedFormat,
    required this.onSelected,
  });

  final TimeFormatPB selectedFormat;
  final Function(TimeFormatPB format) onSelected;

  @override
  State<_TimeOption> createState() => _TimeOptionState();
}

class _TimeOptionState extends State<_TimeOption> {
  TimeFormatPB selectedFormat = TimeFormatPB.TwelveHour;

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
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 4.0),
          child: FlowyText(
            LocaleKeys.grid_field_timeFormat.tr().toUpperCase(),
            fontSize: 13,
            color: Theme.of(context).hintColor,
          ),
        ),
        ...TimeFormatPB.values.mapIndexed((index, format) {
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

class _IncludeTimeOption extends StatefulWidget {
  const _IncludeTimeOption({
    required this.includeTime,
    required this.onToggle,
  });

  final bool includeTime;
  final void Function(bool includeTime) onToggle;

  @override
  State<_IncludeTimeOption> createState() => _IncludeTimeOptionState();
}

class _IncludeTimeOptionState extends State<_IncludeTimeOption> {
  late bool includeTime = widget.includeTime;

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.toggle(
      text: LocaleKeys.grid_field_includeTime.tr(),
      isSelected: includeTime,
      onValueChanged: (value) {
        widget.onToggle(value);
        setState(() {
          includeTime = value;
        });
      },
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
      trailing: Row(
        children: [
          FlowyText(
            selectedFormat.title(),
            color: Theme.of(context).hintColor,
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          builder: (context) {
            return DraggableScrollableSheet(
              expand: false,
              snap: true,
              minChildSize: 0.5,
              builder: (context, scrollController) => _NumberFormatList(
                scrollController: scrollController,
                selectedFormat: selectedFormat,
                onSelected: (type) {
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

class _NumberFormatList extends StatefulWidget {
  const _NumberFormatList({
    this.scrollController,
    required this.selectedFormat,
    required this.onSelected,
  });

  final NumberFormatPB selectedFormat;
  final ScrollController? scrollController;
  final void Function(NumberFormatPB format) onSelected;

  @override
  State<_NumberFormatList> createState() => _NumberFormatListState();
}

class _NumberFormatListState extends State<_NumberFormatList> {
  List<NumberFormatPB> formats = NumberFormatPB.values;

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: widget.scrollController,
      children: [
        const Center(
          child: DragHandle(),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          height: 44.0,
          child: FlowySearchTextField(
            onChanged: (String value) {
              setState(() {
                formats = NumberFormatPB.values
                    .where(
                      (element) => element
                          .title()
                          .toLowerCase()
                          .contains(value.toLowerCase()),
                    )
                    .toList();
              });
            },
          ),
        ),
        ...formats.mapIndexed(
          (index, element) => FlowyOptionTile.checkbox(
            text: element.title(),
            content: Expanded(
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      4.0,
                      16.0,
                      12.0,
                      16.0,
                    ),
                    child: FlowyText(
                      element.title(),
                      fontSize: 16,
                    ),
                  ),
                  FlowyText(
                    element.iconSymbol(),
                    fontSize: 16,
                    color: Theme.of(context).hintColor,
                  ),
                  widget.selectedFormat != element
                      ? const HSpace(30.0)
                      : const HSpace(6.0),
                ],
              ),
            ),
            isSelected: widget.selectedFormat == element,
            showTopBorder: false,
            onTap: () => widget.onSelected(element),
          ),
        ),
      ],
    );
  }
}

// single select or multi select
class _SelectOption extends StatelessWidget {
  _SelectOption({
    required this.mode,
    required this.selectOption,
    required this.onAddOptions,
    required this.onUpdateOptions,
  });

  final List<SelectOptionPB> selectOption;
  final void Function(List<SelectOptionPB> options) onAddOptions;
  final void Function(List<SelectOptionPB> options) onUpdateOptions;
  final FieldOptionMode mode;

  final random = Random();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 4.0),
          child: FlowyText(
            LocaleKeys.grid_field_optionTitle.tr().toUpperCase(),
            fontSize: 13,
            color: Theme.of(context).hintColor,
          ),
        ),
        _SelectOptionList(
          selectOptions: selectOption,
          onUpdateOptions: onUpdateOptions,
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.grid_field_addOption.tr(),
          leftIcon: const FlowySvg(
            FlowySvgs.add_s,
            size: Size.square(20),
          ),
          onTap: () {
            onAddOptions([
              SelectOptionPB(
                id: uuid(),
                name: '',
                color: SelectOptionColorPB.valueOf(
                  random.nextInt(SelectOptionColorPB.values.length),
                ),
              ),
            ]);
          },
        ),
      ],
    );
  }
}

class _SelectOptionList extends StatefulWidget {
  const _SelectOptionList({
    required this.selectOptions,
    required this.onUpdateOptions,
  });

  final List<SelectOptionPB> selectOptions;
  final void Function(List<SelectOptionPB> options) onUpdateOptions;

  @override
  State<_SelectOptionList> createState() => _SelectOptionListState();
}

class _SelectOptionListState extends State<_SelectOptionList> {
  late List<SelectOptionPB> options;

  @override
  void initState() {
    super.initState();

    options = widget.selectOptions;
  }

  @override
  void didUpdateWidget(covariant _SelectOptionList oldWidget) {
    super.didUpdateWidget(oldWidget);

    options = widget.selectOptions;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectOptions.isEmpty) {
      return const SizedBox.shrink();
    }
    return ListView(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      children: widget.selectOptions
          .mapIndexed(
            (index, option) => _SelectOptionTile(
              option: option,
              showTopBorder: index == 0,
              showBottomBorder: index != widget.selectOptions.length - 1,
              onUpdateOption: (option) {
                _updateOption(index, option);
              },
            ),
          )
          .toList(),
    );
  }

  void _updateOption(int index, SelectOptionPB option) {
    final options = [...this.options];
    options[index] = option;
    this.options = options;
    widget.onUpdateOptions(options);
  }
}

class _SelectOptionTile extends StatefulWidget {
  const _SelectOptionTile({
    required this.option,
    required this.showTopBorder,
    required this.showBottomBorder,
    required this.onUpdateOption,
  });

  final SelectOptionPB option;
  final bool showTopBorder;
  final bool showBottomBorder;
  final void Function(SelectOptionPB option) onUpdateOption;

  @override
  State<_SelectOptionTile> createState() => _SelectOptionTileState();
}

class _SelectOptionTileState extends State<_SelectOptionTile> {
  final TextEditingController controller = TextEditingController();
  late SelectOptionPB option;

  @override
  void initState() {
    super.initState();

    controller.text = widget.option.name;
    option = widget.option;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowyOptionTile.textField(
      controller: controller,
      textFieldHintText: LocaleKeys.grid_field_typeANewOption.tr(),
      showTopBorder: widget.showTopBorder,
      showBottomBorder: widget.showBottomBorder,
      trailing: _SelectOptionColor(
        color: option.color,
        onChanged: (color) {
          setState(() {
            option.freeze();
            option = option.rebuild((p0) => p0.color = color);
            widget.onUpdateOption(option);
          });
          context.pop();
        },
      ),
      onTextChanged: (name) {
        setState(() {
          option.freeze();
          option = option.rebuild((p0) => p0.name = name);
          widget.onUpdateOption(option);
        });
      },
    );
  }
}

class _SelectOptionColor extends StatelessWidget {
  const _SelectOptionColor({
    required this.color,
    required this.onChanged,
  });

  final SelectOptionColorPB color;
  final void Function(SelectOptionColorPB) onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showMobileBottomSheet(
          context,
          showHeader: true,
          showCloseButton: true,
          title: LocaleKeys.grid_selectOption_colorPanelTitle.tr(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          builder: (context) {
            return OptionColorList(
              selectedColor: color,
              onSelectedColor: onChanged,
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color.toColor(context),
          borderRadius: Corners.s10Border,
        ),
        width: 32,
        height: 32,
        alignment: Alignment.center,
        child: const FlowySvg(
          FlowySvgs.arrow_down_s,
          size: Size.square(20),
        ),
      ),
    );
  }
}
