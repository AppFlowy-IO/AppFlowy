import 'package:app_flowy/plugins/grid/application/filter/select_option_filter_list_bloc.dart';
import 'package:app_flowy/plugins/grid/presentation/layout/sizes.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/cell/select_option_cell/extension.dart';
import 'package:app_flowy/plugins/grid/presentation/widgets/filter/filter_info.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/style_widget/scrolling/styled_list.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/field_entities.pbenum.dart';
import 'package:flowy_sdk/protobuf/flowy-grid/select_type_option.pb.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'select_option_loader.dart';

class SelectOptionFilterList extends StatelessWidget {
  final FilterInfo filterInfo;
  final List<String> selectedOptionIds;
  final Function(List<String>) onSelectedOptions;
  const SelectOptionFilterList({
    required this.filterInfo,
    required this.selectedOptionIds,
    required this.onSelectedOptions,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        late SelectOptionFilterListBloc bloc;
        if (filterInfo.fieldInfo.fieldType == FieldType.SingleSelect) {
          bloc = SelectOptionFilterListBloc(
            viewId: filterInfo.viewId,
            fieldPB: filterInfo.fieldInfo.field,
            selectedOptionIds: selectedOptionIds,
            delegate: SingleSelectOptionFilterDelegateImpl(filterInfo),
          );
        } else {
          bloc = SelectOptionFilterListBloc(
            viewId: filterInfo.viewId,
            fieldPB: filterInfo.fieldInfo.field,
            selectedOptionIds: selectedOptionIds,
            delegate: MultiSelectOptionFilterDelegateImpl(filterInfo),
          );
        }

        bloc.add(const SelectOptionFilterListEvent.initial());
        return bloc;
      },
      child:
          BlocListener<SelectOptionFilterListBloc, SelectOptionFilterListState>(
        listenWhen: (previous, current) =>
            previous.selectedOptionIds != current.selectedOptionIds,
        listener: (context, state) {
          onSelectedOptions(state.selectedOptionIds.toList());
        },
        child: BlocBuilder<SelectOptionFilterListBloc,
            SelectOptionFilterListState>(
          builder: (context, state) {
            return ListView.separated(
              shrinkWrap: true,
              controller: ScrollController(),
              itemCount: state.visibleOptions.length,
              separatorBuilder: (context, index) {
                return VSpace(GridSize.typeOptionSeparatorHeight);
              },
              physics: StyledScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                final option = state.visibleOptions[index];
                return _SelectOptionFilterCell(
                  option: option.optionPB,
                  isSelected: option.isSelected,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SelectOptionFilterCell extends StatefulWidget {
  final SelectOptionPB option;
  final bool isSelected;
  const _SelectOptionFilterCell({
    required this.option,
    required this.isSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<_SelectOptionFilterCell> createState() =>
      _SelectOptionFilterCellState();
}

class _SelectOptionFilterCellState extends State<_SelectOptionFilterCell> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: SelectOptionTagCell(
        option: widget.option,
        onSelected: (option) {
          if (widget.isSelected) {
            context
                .read<SelectOptionFilterListBloc>()
                .add(SelectOptionFilterListEvent.unselectOption(option));
          } else {
            context
                .read<SelectOptionFilterListBloc>()
                .add(SelectOptionFilterListEvent.selectOption(option));
          }
        },
        children: [
          if (widget.isSelected)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: svgWidget("grid/checkmark"),
            ),
        ],
      ),
    );
  }
}
