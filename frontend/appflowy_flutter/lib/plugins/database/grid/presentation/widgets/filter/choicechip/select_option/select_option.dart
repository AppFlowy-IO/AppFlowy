import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/filter/select_option_loader.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../disclosure_button.dart';
import '../choicechip.dart';

import 'condition_list.dart';
import 'option_list.dart';

class SelectOptionFilterChoicechip extends StatelessWidget {
  const SelectOptionFilterChoicechip({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  Widget build(BuildContext context) {
    return AppFlowyPopover(
      constraints: BoxConstraints.loose(const Size(240, 160)),
      direction: PopoverDirection.bottomWithCenterAligned,
      popupBuilder: (_) {
        return BlocProvider.value(
          value: context.read<FilterEditorBloc>(),
          child: SelectOptionFilterEditor(filterId: filterId),
        );
      },
      child: SingleFilterBlocSelector<SelectOptionFilter>(
        filterId: filterId,
        builder: (context, filter, field) {
          return ChoiceChipButton(
            fieldInfo: field,
            filterDesc: filter.getDescription(field),
          );
        },
      ),
    );
  }
}

class SelectOptionFilterEditor extends StatefulWidget {
  const SelectOptionFilterEditor({
    super.key,
    required this.filterId,
  });

  final String filterId;

  @override
  State<SelectOptionFilterEditor> createState() =>
      _SelectOptionFilterEditorState();
}

class _SelectOptionFilterEditorState extends State<SelectOptionFilterEditor> {
  final popoverMutex = PopoverMutex();

  @override
  void dispose() {
    popoverMutex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleFilterBlocSelector<SelectOptionFilter>(
      filterId: widget.filterId,
      builder: (context, filter, field) {
        final List<Widget> slivers = [
          SliverToBoxAdapter(child: _buildFilterPanel(filter, field)),
        ];

        if (![
          SelectOptionFilterConditionPB.OptionIsEmpty,
          SelectOptionFilterConditionPB.OptionIsNotEmpty,
        ].contains(filter.condition)) {
          final delegate = makeDelegate(field);
          slivers
            ..add(const SliverToBoxAdapter(child: VSpace(4)))
            ..add(
              SliverToBoxAdapter(
                child: SelectOptionFilterList(
                  filter: filter,
                  field: field,
                  delegate: delegate,
                  options: delegate.getOptions(field),
                ),
              ),
            );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: slivers,
            physics: StyledScrollPhysics(),
          ),
        );
      },
    );
  }

  Widget _buildFilterPanel(
    SelectOptionFilter filter,
    FieldInfo field,
  ) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: FlowyText(
              field.field.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(4),
          SelectOptionFilterConditionList(
            filter: filter,
            fieldType: field.fieldType,
            popoverMutex: popoverMutex,
            onCondition: (condition) {
              final newFilter = filter.copyWith(condition: condition);
              context
                  .read<FilterEditorBloc>()
                  .add(FilterEditorEvent.updateFilter(newFilter));
            },
          ),
          DisclosureButton(
            popoverMutex: popoverMutex,
            onAction: (action) {
              switch (action) {
                case FilterDisclosureAction.delete:
                  context
                      .read<FilterEditorBloc>()
                      .add(FilterEditorEvent.deleteFilter(filter.filterId));
                  break;
              }
            },
          ),
        ],
      ),
    );
  }

  SelectOptionFilterDelegate makeDelegate(FieldInfo field) =>
      field.fieldType == FieldType.SingleSelect
          ? const SingleSelectOptionFilterDelegateImpl()
          : const MultiSelectOptionFilterDelegateImpl();
}
