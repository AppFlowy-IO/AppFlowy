import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/grid/application/filter/select_option_filter_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/filter/filter_info.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/select_option_cell_editor.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flowy_infra_ui/style_widget/hover.dart';
import 'package:flowy_infra_ui/widget/spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectOptionFilterList extends StatelessWidget {
  const SelectOptionFilterList({
    super.key,
    required this.filterInfo,
    required this.selectedOptionIds,
  });

  final FilterInfo filterInfo;
  final List<String> selectedOptionIds;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SelectOptionFilterBloc, SelectOptionFilterState>(
      builder: (context, state) {
        final selectedOptionIds = state.filter.optionIds;
        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: state.options.length,
          separatorBuilder: (context, index) =>
              VSpace(GridSize.typeOptionSeparatorHeight),
          itemBuilder: (context, index) {
            final option = state.options[index];
            final isSelected = selectedOptionIds.contains(option.id);
            return SelectOptionFilterCell(
              option: option,
              isSelected: isSelected,
            );
          },
        );
      },
    );
  }
}

class SelectOptionFilterCell extends StatefulWidget {
  const SelectOptionFilterCell({
    super.key,
    required this.option,
    required this.isSelected,
  });

  final SelectOptionPB option;
  final bool isSelected;

  @override
  State<SelectOptionFilterCell> createState() => _SelectOptionFilterCellState();
}

class _SelectOptionFilterCellState extends State<SelectOptionFilterCell> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: GridSize.popoverItemHeight,
      child: FlowyHover(
        resetHoverOnRebuild: false,
        style: HoverStyle(
          hoverColor: AFThemeExtension.of(context).lightGreyHover,
        ),
        child: SelectOptionTagCell(
          option: widget.option,
          onSelected: () {
            if (widget.isSelected) {
              context
                  .read<SelectOptionFilterBloc>()
                  .add(SelectOptionFilterEvent.unSelectOption(widget.option));
            } else {
              context
                  .read<SelectOptionFilterBloc>()
                  .add(SelectOptionFilterEvent.selectOption(widget.option));
            }
          },
          children: [
            if (widget.isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: FlowySvg(FlowySvgs.check_s),
              ),
          ],
        ),
      ),
    );
  }
}
