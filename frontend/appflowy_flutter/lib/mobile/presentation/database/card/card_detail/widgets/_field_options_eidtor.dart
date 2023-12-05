import 'dart:math';
import 'dart:typed_data';

import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/base/option_color_list.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/bottom_sheet.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/_field_options.dart';
import 'package:appflowy/mobile/presentation/database/card/card_detail/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/application/field/field_service.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/number_format_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_service.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/date.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
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

enum FieldOptionMode {
  add,
  edit,
}

class FieldOptionValues {
  FieldOptionValues({
    required this.type,
    required this.name,
    this.dateFormate,
    this.timeFormat,
    this.numberFormat,
    this.selectOption = const [],
  });

  FieldType type;
  String name;

  // FieldType.Date
  DateFormatPB? dateFormate;
  TimeFormatPB? timeFormat;

  // FieldType.Num
  NumberFormatPB? numberFormat;

  // FieldType.Select
  // FieldType.MultiSelect
  List<SelectOptionPB> selectOption;

  Future<void> create({
    required String viewId,
  }) async {
    await TypeOptionBackendService.createFieldTypeOption(
      viewId: viewId,
      fieldType: type,
      fieldName: name,
      typeOptionData: toTypeOptionBuffer(),
    );
  }

  Uint8List? toTypeOptionBuffer() {
    switch (type) {
      case FieldType.RichText:
      case FieldType.URL:
      case FieldType.Checkbox:
        return null;
      case FieldType.Number:
        return NumberTypeOptionPB(
          format: numberFormat,
        ).writeToBuffer();
      case FieldType.DateTime:
        return DateTypeOptionPB(
          dateFormat: dateFormate,
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
      default:
        throw UnimplementedError();
    }
  }

  static Future<FieldOptionValues?> get({
    required String viewId,
    required String fieldId,
    required FieldType fieldType,
  }) async {
    final service = FieldBackendService(viewId: viewId, fieldId: fieldId);
    final result = await service.getFieldTypeOptionData(fieldType: fieldType);
    return result.fold(
      (option) {
        final type = option.field_2.fieldType;
        final buffer = option.typeOptionData;
        return FieldOptionValues(
          type: type,
          name: option.field_2.name,
          numberFormat: type == FieldType.Number
              ? NumberTypeOptionPB.fromBuffer(buffer).format
              : null,
          dateFormate: type == FieldType.DateTime
              ? DateTypeOptionPB.fromBuffer(buffer).dateFormat
              : null,
          timeFormat: type == FieldType.DateTime
              ? DateTypeOptionPB.fromBuffer(buffer).timeFormat
              : null,
          selectOption: switch (type) {
            FieldType.SingleSelect =>
              SingleSelectTypeOptionPB.fromBuffer(buffer).options,
            FieldType.MultiSelect =>
              MultiSelectTypeOptionPB.fromBuffer(buffer).options,
            _ => [],
          },
        );
      },
      (error) => null,
    );
  }
}

enum FieldOptionAction {
  hide,
  duplicate,
  delete,
}

class FieldOptionEditor extends StatefulWidget {
  const FieldOptionEditor({
    super.key,
    required this.mode,
    required this.defaultValues,
    required this.onOptionValuesChanged,
    this.onAction,
    this.isPrimary = false,
  });

  final FieldOptionMode mode;
  final FieldOptionValues defaultValues;
  final void Function(FieldOptionValues values) onOptionValuesChanged;

  // only used in edit mode
  final void Function(FieldOptionAction action)? onAction;

  // the primary field can't be deleted, duplicated, and changed type
  final bool isPrimary;

  @override
  State<FieldOptionEditor> createState() => _FieldOptionEditorState();
}

class _FieldOptionEditorState extends State<FieldOptionEditor> {
  final controller = TextEditingController();

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
      color: Theme.of(context).colorScheme.secondaryContainer,
      height: MediaQuery.of(context).size.height,
      child: SingleChildScrollView(
        child: Column(
          children: [
            const _Divider(),
            OptionTextField(
              controller: controller,
              type: values.type,
              onTextChanged: (value) {
                _updateOptionValues(name: value);
              },
            ),
            const _Divider(),
            if (!widget.isPrimary) ...[
              _PropertyType(
                type: values.type,
                onSelected: (type) => setState(
                  () {
                    if (widget.mode == FieldOptionMode.add) {
                      controller.text = type.i18n;
                    }
                    _updateOptionValues(type: type, name: type.i18n);
                  },
                ),
              ),
              const _Divider(),
              if (option.isNotEmpty) ...[
                ...option,
                const _Divider(),
              ],
            ],
            ..._buildOptionActions(),
            const _Divider(),
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
            selectedFormat: values.dateFormate ?? DateFormatPB.Local,
            onSelected: (format) => _updateOptionValues(
              dateFormate: format,
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
    return switch (widget.mode) {
      FieldOptionMode.add => [],
      FieldOptionMode.edit => [
          FlowyOptionTile.text(
            text: LocaleKeys.grid_field_hide.tr(),
            leftIcon: const FlowySvg(FlowySvgs.hide_s),
            onTap: () => widget.onAction?.call(FieldOptionAction.hide),
          ),
          if (!widget.isPrimary) ...[
            FlowyOptionTile.text(
              showTopBorder: false,
              text: LocaleKeys.button_duplicate.tr(),
              leftIcon: const FlowySvg(FlowySvgs.copy_s),
              onTap: () => widget.onAction?.call(FieldOptionAction.duplicate),
            ),
            FlowyOptionTile.text(
              showTopBorder: false,
              text: LocaleKeys.button_delete.tr(),
              textColor: Theme.of(context).colorScheme.error,
              leftIcon: FlowySvg(
                FlowySvgs.delete_s,
                color: Theme.of(context).colorScheme.error,
              ),
              onTap: () => widget.onAction?.call(FieldOptionAction.delete),
            ),
          ],
        ]
    };
  }

  void _updateOptionValues({
    FieldType? type,
    String? name,
    DateFormatPB? dateFormate,
    TimeFormatPB? timeFormat,
    NumberFormatPB? numberFormat,
    List<SelectOptionPB>? selectOption,
  }) {
    if (type != null) {
      values.type = type;
    }
    if (name != null) {
      values.name = name;
    }
    if (dateFormate != null) {
      values.dateFormate = dateFormate;
    }
    if (timeFormat != null) {
      values.timeFormat = timeFormat;
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          FlowySvg(
            type.smallSvgData,
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
          padding: const EdgeInsets.symmetric(
            vertical: 6.0,
            horizontal: 16.0,
          ),
          child: FlowyText(
            LocaleKeys.grid_field_timeFormat.tr(),
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
        crossAxisAlignment: CrossAxisAlignment.center,
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
          padding: const EdgeInsets.symmetric(
            vertical: 6.0,
            horizontal: 16.0,
          ),
          child: FlowyText(
            LocaleKeys.grid_field_optionTitle.tr(),
            color: Theme.of(context).hintColor,
          ),
        ),
        _SelectOptionList(
          selectOptions: selectOption,
          onUpdateOptions: onUpdateOptions,
        ),
        FlowyOptionTile.text(
          text: LocaleKeys.grid_field_addOption.tr(),
          leftIcon: const FlowySvg(FlowySvgs.add_s),
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
  State<_SelectOptionTile> createState() => __SelectOptionTileState();
}

class __SelectOptionTileState extends State<_SelectOptionTile> {
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
      textFieldPadding: const EdgeInsets.symmetric(horizontal: 16.0),
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
