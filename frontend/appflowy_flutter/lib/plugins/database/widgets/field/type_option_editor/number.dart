import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/field/type_option/number_format_bloc.dart';
import 'package:appflowy/plugins/database/application/field/type_option/type_option_data_parser.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:protobuf/protobuf.dart';

import '../../../grid/presentation/layout/sizes.dart';
import '../../../grid/presentation/widgets/common/type_option_separator.dart';
import 'builder.dart';

class NumberTypeOptionEditorFactory implements TypeOptionEditorFactory {
  const NumberTypeOptionEditorFactory();

  @override
  Widget? build({
    required BuildContext context,
    required String viewId,
    required FieldPB field,
    required PopoverMutex popoverMutex,
    required TypeOptionDataCallback onTypeOptionUpdated,
  }) {
    final typeOption = _parseTypeOptionData(field.typeOptionData);

    final selectNumUnitButton = SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        rightIcon: const FlowySvg(FlowySvgs.more_s),
        text: FlowyText(
          lineHeight: 1.0,
          typeOption.format.title(),
        ),
      ),
    );

    final numFormatTitle = Container(
      padding: const EdgeInsets.only(left: 6),
      height: GridSize.popoverItemHeight,
      alignment: Alignment.centerLeft,
      child: FlowyText.regular(
        LocaleKeys.grid_field_numberFormat.tr(),
        color: Theme.of(context).hintColor,
        fontSize: 11,
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          numFormatTitle,
          AppFlowyPopover(
            mutex: popoverMutex,
            triggerActions:
                PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
            offset: const Offset(16, 0),
            constraints: BoxConstraints.loose(const Size(460, 440)),
            margin: EdgeInsets.zero,
            child: selectNumUnitButton,
            popupBuilder: (BuildContext popoverContext) {
              return NumberFormatList(
                selectedFormat: typeOption.format,
                onSelected: (format) {
                  final newTypeOption = _updateNumberFormat(typeOption, format);
                  onTypeOptionUpdated(newTypeOption.writeToBuffer());
                  PopoverContainer.of(popoverContext).close();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  NumberTypeOptionPB _parseTypeOptionData(List<int> data) {
    return NumberTypeOptionDataParser().fromBuffer(data);
  }

  NumberTypeOptionPB _updateNumberFormat(
    NumberTypeOptionPB typeOption,
    NumberFormatPB format,
  ) {
    typeOption.freeze();
    return typeOption.rebuild((typeOption) => typeOption.format = format);
  }
}

typedef SelectNumberFormatCallback = void Function(NumberFormatPB format);

class NumberFormatList extends StatelessWidget {
  const NumberFormatList({
    super.key,
    required this.selectedFormat,
    required this.onSelected,
  });

  final NumberFormatPB selectedFormat;
  final SelectNumberFormatCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NumberFormatBloc(),
      child: SizedBox(
        width: 180,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _FilterTextField(),
            const TypeOptionSeparator(spacing: 0.0),
            BlocBuilder<NumberFormatBloc, NumberFormatState>(
              builder: (context, state) {
                final cells = state.formats.map((format) {
                  return NumberFormatCell(
                    isSelected: format == selectedFormat,
                    format: format,
                    onSelected: (format) {
                      onSelected(format);
                    },
                  );
                }).toList();

                final list = ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (context, index) {
                    return VSpace(GridSize.typeOptionSeparatorHeight);
                  },
                  itemCount: cells.length,
                  itemBuilder: (BuildContext context, int index) {
                    return cells[index];
                  },
                  padding: const EdgeInsets.all(6.0),
                );
                return Flexible(child: list);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NumberFormatCell extends StatelessWidget {
  const NumberFormatCell({
    super.key,
    required this.format,
    required this.isSelected,
    required this.onSelected,
  });

  final NumberFormatPB format;
  final bool isSelected;
  final SelectNumberFormatCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final checkmark = isSelected ? const FlowySvg(FlowySvgs.check_s) : null;

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText(
          format.title(),
          lineHeight: 1.0,
        ),
        onTap: () => onSelected(format),
        rightIcon: checkmark,
      ),
    );
  }
}

class _FilterTextField extends StatelessWidget {
  const _FilterTextField();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: FlowyTextField(
        onChanged: (text) => context
            .read<NumberFormatBloc>()
            .add(NumberFormatEvent.setFilter(text)),
      ),
    );
  }
}
