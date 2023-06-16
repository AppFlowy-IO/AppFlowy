import 'package:appflowy/plugins/database_view/grid/application/filter/select_option_filter_list_bloc.dart';
import 'package:appflowy/plugins/database_view/grid/presentation/layout/sizes.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option.pb.dart';
import 'package:flowy_infra/image.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/field_entities.pbenum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../widgets/row/cells/select_option_cell/extension.dart';
import '../../filter_info.dart';
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
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              controller: ScrollController(),
              itemCount: state.visibleOptions.length,
              separatorBuilder: (context, index) {
                return VSpace(GridSize.typeOptionSeparatorHeight);
              },
              itemBuilder: (BuildContext context, int index) {
                final option = state.visibleOptions[index];
                return SelectOptionFilterCell(
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

class SelectOptionFilterCell extends StatefulWidget {
  final SelectOptionPB option;
  final bool isSelected;
  const SelectOptionFilterCell({
    required this.option,
    required this.isSelected,
    Key? key,
  }) : super(key: key);

  @override
  State<SelectOptionFilterCell> createState() => _SelectOptionFilterCellState();
}

class _SelectOptionFilterCellState extends State<SelectOptionFilterCell> {
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
