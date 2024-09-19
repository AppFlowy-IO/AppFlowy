import 'package:appflowy/plugins/database/application/field/field_controller.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/filter/select_option_filter_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_filter.pb.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../disclosure_button.dart';
import '../../filter_info.dart';
import '../choicechip.dart';

import 'condition_list.dart';
import 'option_list.dart';
import 'select_option_loader.dart';

class SelectOptionFilterChoicechip extends StatelessWidget {
  const SelectOptionFilterChoicechip({
    super.key,
    required this.fieldController,
    required this.filterInfo,
  });

  final FieldController fieldController;
  final FilterInfo filterInfo;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SelectOptionFilterBloc(
        fieldController: fieldController,
        filterInfo: filterInfo,
        delegate: filterInfo.fieldInfo.fieldType == FieldType.SingleSelect
            ? SingleSelectOptionFilterDelegateImpl(
                filterInfo: filterInfo,
              )
            : MultiSelectOptionFilterDelegateImpl(
                filterInfo: filterInfo,
              ),
      ),
      child: Builder(
        builder: (context) {
          return AppFlowyPopover(
            constraints: BoxConstraints.loose(const Size(240, 160)),
            direction: PopoverDirection.bottomWithCenterAligned,
            popupBuilder: (_) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider.value(
                    value: context.read<SelectOptionFilterBloc>(),
                  ),
                  BlocProvider.value(
                    value: context.read<FilterEditorBloc>(),
                  ),
                ],
                child: const SelectOptionFilterEditor(),
              );
            },
            child: BlocBuilder<SelectOptionFilterBloc, SelectOptionFilterState>(
              builder: (context, state) {
                return ChoiceChipButton(
                  filterInfo: state.filterInfo,
                  filterDesc: _makeFilterDesc(state),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _makeFilterDesc(SelectOptionFilterState state) {
    final condition = state.filter.condition;

    if (condition == SelectOptionFilterConditionPB.OptionIsEmpty ||
        condition == SelectOptionFilterConditionPB.OptionIsNotEmpty) {
      return condition.i18n;
    }

    String optionNames = "";
    for (final option in state.options) {
      if (state.filter.optionIds.contains(option.id)) {
        optionNames += "${option.name} ";
      }
    }
    return "${condition.i18n} $optionNames";
  }
}

class SelectOptionFilterEditor extends StatefulWidget {
  const SelectOptionFilterEditor({super.key});

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
    return BlocBuilder<SelectOptionFilterBloc, SelectOptionFilterState>(
      builder: (context, state) {
        final List<Widget> slivers = [
          SliverToBoxAdapter(child: _buildFilterPanel(state)),
        ];

        if (state.filter.condition !=
                SelectOptionFilterConditionPB.OptionIsEmpty &&
            state.filter.condition !=
                SelectOptionFilterConditionPB.OptionIsNotEmpty) {
          slivers
            ..add(const SliverToBoxAdapter(child: VSpace(4)))
            ..add(
              SliverToBoxAdapter(
                child: SelectOptionFilterList(
                  filterInfo: state.filterInfo,
                  selectedOptionIds: state.filter.optionIds,
                  onSelectedOptions: (optionIds) {
                    context.read<SelectOptionFilterBloc>().add(
                          SelectOptionFilterEvent.updateContent(
                            optionIds,
                          ),
                        );
                  },
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
    SelectOptionFilterState state,
  ) {
    return SizedBox(
      height: 20,
      child: Row(
        children: [
          Expanded(
            child: FlowyText(
              state.filterInfo.fieldInfo.field.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const HSpace(4),
          SelectOptionFilterConditionList(
            filterInfo: state.filterInfo,
            popoverMutex: popoverMutex,
            onCondition: (condition) {
              context.read<SelectOptionFilterBloc>().add(
                    SelectOptionFilterEvent.updateCondition(condition),
                  );
            },
          ),
          DisclosureButton(
            popoverMutex: popoverMutex,
            onAction: (action) {
              switch (action) {
                case FilterDisclosureAction.delete:
                  context.read<FilterEditorBloc>().add(
                        FilterEditorEvent.deleteFilter(
                          state.filterInfo.filterId,
                        ),
                      );
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
