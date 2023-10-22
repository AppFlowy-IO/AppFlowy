import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/number_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/number_format_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/number_entities.pbenum.dart';
import 'package:appflowy_popover/appflowy_popover.dart';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';

import '../../../layout/sizes.dart';
import '../../common/type_option_separator.dart';
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
  Widget? build(BuildContext context) {
    return Column(
      children: [
        VSpace(GridSize.typeOptionSeparatorHeight),
        const TypeOptionSeparator(),
        _widget,
      ],
    );
  }
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
    return BlocProvider(
      create: (context) =>
          NumberTypeOptionBloc(typeOptionContext: typeOptionContext),
      child: BlocConsumer<NumberTypeOptionBloc, NumberTypeOptionState>(
        listener: (context, state) =>
            typeOptionContext.typeOption = state.typeOption,
        builder: (context, state) {
          final selectNumUnitButton = SizedBox(
            height: GridSize.popoverItemHeight,
            child: FlowyButton(
              margin: GridSize.typeOptionContentInsets,
              rightIcon: const FlowySvg(FlowySvgs.more_s),
              text: FlowyText.regular(
                state.typeOption.format.title(),
              ),
            ),
          );

          final numFormatTitle = Container(
            padding: const EdgeInsets.only(left: 6),
            height: GridSize.popoverItemHeight,
            alignment: Alignment.centerLeft,
            child: FlowyText.medium(
              color: Theme.of(context).colorScheme.outline,
              LocaleKeys.grid_field_numberFormat.tr(),
            ),
          );
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                numFormatTitle,
                AppFlowyPopover(
                  mutex: popoverMutex,
                  triggerActions:
                      PopoverTriggerFlags.hover | PopoverTriggerFlags.click,
                  offset: const Offset(8, 0),
                  constraints: BoxConstraints.loose(const Size(460, 440)),
                  margin: EdgeInsets.zero,
                  child: selectNumUnitButton,
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

typedef SelectNumberFormatCallback = Function(NumberFormatPB format);

class NumberFormatList extends StatelessWidget {
  final SelectNumberFormatCallback onSelected;
  final NumberFormatPB selectedFormat;
  const NumberFormatList({
    required this.selectedFormat,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

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
                  controller: ScrollController(),
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
  final NumberFormatPB format;
  final bool isSelected;
  final Function(NumberFormatPB format) onSelected;
  const NumberFormatCell({
    required this.isSelected,
    required this.format,
    required this.onSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget? checkmark;
    if (isSelected) {
      checkmark = const FlowySvg(FlowySvgs.check_s);
    }

    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyButton(
        text: FlowyText.medium(format.title()),
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
