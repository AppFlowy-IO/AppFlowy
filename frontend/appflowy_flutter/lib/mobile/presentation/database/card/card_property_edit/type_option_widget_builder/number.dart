import 'package:appflowy/mobile/presentation/database/card/card_property_edit/widgets/widgets.dart';
import 'package:appflowy/mobile/presentation/widgets/widgets.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/number_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/number_format_bloc.dart';
import 'package:appflowy/plugins/database_view/application/field/type_option/type_option_context.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/field_type_option_editor.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/builder.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/number_entities.pbenum.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:go_router/go_router.dart';

class NumberTypeOptionMobileWidgetBuilder extends TypeOptionWidgetBuilder {
  final NumberTypeOptionMobileWidget _widget;

  NumberTypeOptionMobileWidgetBuilder(
    NumberTypeOptionContext typeOptionContext,
  ) : _widget = NumberTypeOptionMobileWidget(
          typeOptionContext: typeOptionContext,
        );

  @override
  Widget? build(BuildContext context) {
    return _widget;
  }
}

class NumberTypeOptionMobileWidget extends TypeOptionWidget {
  final NumberTypeOptionContext typeOptionContext;

  const NumberTypeOptionMobileWidget({
    super.key,
    required this.typeOptionContext,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          NumberTypeOptionBloc(typeOptionContext: typeOptionContext),
      child: BlocConsumer<NumberTypeOptionBloc, NumberTypeOptionState>(
        listener: (context, state) =>
            typeOptionContext.typeOption = state.typeOption,
        builder: (context, state) {
          return GestureDetector(
            child: PropertyEditContainer(
              child: Row(
                children: [
                  PropertyTitle(LocaleKeys.grid_field_numberFormat.tr()),
                  const Spacer(),
                  const HSpace(4),
                  Text(
                    state.typeOption.format.title(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ),
            ),
            onTap: () => showFlowyMobileBottomSheet(
              context,
              isScrollControlled: true,
              title: LocaleKeys.grid_field_numberFormat.tr(),
              builder: (bottomsheetContext) => GestureDetector(
                child: NumberFormatList(
                  onSelected: (format) {
                    context
                        .read<NumberTypeOptionBloc>()
                        .add(NumberTypeOptionEvent.didSelectFormat(format));
                    bottomsheetContext.pop();
                  },
                  selectedFormat: state.typeOption.format,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

typedef SelectNumberFormatCallback = Function(NumberFormatPB format);

class NumberFormatList extends StatelessWidget {
  const NumberFormatList({
    super.key,
    required this.selectedFormat,
    required this.onSelected,
  });

  final SelectNumberFormatCallback onSelected;
  final NumberFormatPB selectedFormat;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NumberFormatBloc(),
      child: Column(
        children: [
          const _FilterTextField(),
          const VSpace(16),
          SizedBox(
            height: 300,
            child: BlocBuilder<NumberFormatBloc, NumberFormatState>(
              builder: (context, state) {
                final List<NumberFormatPB> formatList = state.formats;
                return ListView.builder(
                  itemCount: formatList.length,
                  itemBuilder: (BuildContext context, int index) {
                    final format = formatList[index];
                    return RadioListTile<NumberFormatPB>(
                      controlAffinity: ListTileControlAffinity.trailing,
                      visualDensity: VisualDensity.compact,
                      value: format,
                      groupValue: selectedFormat,
                      onChanged: (format) => onSelected(format!),
                      title: Text(format.title()),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterTextField extends StatelessWidget {
  const _FilterTextField();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onChanged: (text) => context
            .read<NumberFormatBloc>()
            .add(NumberFormatEvent.setFilter(text)),
      ),
    );
  }
}
