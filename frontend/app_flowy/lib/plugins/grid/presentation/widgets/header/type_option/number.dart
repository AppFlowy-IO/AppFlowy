import 'package:app_flowy/plugins/grid/application/field/type_option/number_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/number_format_bloc.dart';
import 'package:app_flowy/plugins/grid/application/field/type_option/type_option_context.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/format.pbenum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart' hide NumberFormat;
import 'package:app_flowy/generated/locale_keys.g.dart';

import '../../../layout/sizes.dart';
import '../../common/text_field.dart';
import '../field_type_option_editor.dart';
import 'builder.dart';

class NumberTypeOptionWidgetBuilder extends TypeOptionWidgetBuilder {
  final NumberTypeOptionWidget _widget;

  NumberTypeOptionWidgetBuilder(
    NumberTypeOptionContext typeOptionContext,
    PopoverMutex popoverMutex,
  ) : _widget = NumberTypeOptionWidget(
          typeOptionContext: typeOptionContext,
          popoverMutex: popoverMutex,
        );

  @override
  Widget? build(BuildContext context) => _widget;
}

class NumberTypeOptionWidget extends TypeOptionWidget {
  final NumberTypeOptionContext typeOptionContext;
  final PopoverMutex popoverMutex;
  const NumberTypeOptionWidget({
    required this.typeOptionContext,
    required this.popoverMutex,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return BlocProvider(
      create: (context) =>
          NumberTypeOptionBloc(typeOptionContext: typeOptionContext),
      child: SizedBox(
        height: GridSize.typeOptionItemHeight,
        child: BlocConsumer<NumberTypeOptionBloc, NumberTypeOptionState>(
          listener: (context, state) =>
              typeOptionContext.typeOption = state.typeOption,
          builder: (context, state) {
            return AppFlowyPopover(
              mutex: popoverMutex,
              triggerActions:
                  PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
              offset: const Offset(20, 0),
              constraints: BoxConstraints.loose(const Size(460, 440)),
              child: FlowyButton(
                margin: GridSize.typeOptionContentInsets,
                hoverColor: theme.hover,
                rightIcon: svgWidget("grid/more", color: theme.iconColor),
                text: Row(
                  children: [
                    FlowyText.medium(LocaleKeys.grid_field_numberFormat.tr(),
                        fontSize: 12),
                    // const HSpace(6),
                    const Spacer(),
                    FlowyText.regular(state.typeOption.format.title(),
                        fontSize: 12),
                  ],
                ),
              ),
              popupBuilder: (BuildContext popoverContext) {
                return NumberFormatList(
                  onSelected: (format) {
                    context
                        .read<NumberTypeOptionBloc>()
                        .add(NumberTypeOptionEvent.didSelectFormat(format));
                    PopoverContainer.of(popoverContext).close();
                  },
                  selectedFormat: state.typeOption.format,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

typedef SelectNumberFormatCallback = Function(NumberFormat format);

class NumberFormatList extends StatelessWidget {
  final SelectNumberFormatCallback onSelected;
  final NumberFormat selectedFormat;
  const NumberFormatList(
      {required this.selectedFormat, required this.onSelected, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NumberFormatBloc(),
      child: SizedBox(
        width: 180,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FilterTextField(),
            const VSpace(10),
            BlocBuilder<NumberFormatBloc, NumberFormatState>(
              builder: (context, state) {
                final cells = state.formats.map((format) {
                  return NumberFormatCell(
                      isSelected: format == selectedFormat,
                      format: format,
                      onSelected: (format) {
                        onSelected(format);
                      });
                }).toList();

                final list = ListView.separated(
                  shrinkWrap: true,
                  controller: ScrollController(),
                  separatorBuilder: (context, index) {
                    return VSpace(GridSize.typeOptionSeparatorHeight);
                  },
                  itemCount: cells.length,
                  itemBuilder: (BuildContext context, int index) {
                    return cells[index];
                  },
                );
                return Expanded(child: list);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NumberFormatCell extends StatelessWidget {
  final NumberFormat format;
  final bool isSelected;
  final Function(NumberFormat format) onSelected;
  const NumberFormatCell({
    required this.isSelected,
    required this.format,
    required this.onSelected,
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
        text: FlowyText.medium(format.title(), fontSize: 12),
        hoverColor: theme.hover,
        onTap: () => onSelected(format),
        rightIcon: checkmark,
      ),
    );
  }
}

class _FilterTextField extends StatelessWidget {
  const _FilterTextField({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return InputTextField(
      text: "",
      onCanceled: () {},
      onChanged: (text) {
        context.read<NumberFormatBloc>().add(NumberFormatEvent.setFilter(text));
      },
    );
  }
}
