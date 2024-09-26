import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/field/field_info.dart';
import 'package:appflowy/plugins/database/application/field/filter_entities.dart';
import 'package:appflowy/plugins/database/grid/application/filter/filter_editor_bloc.dart';
import 'package:appflowy/plugins/database/grid/application/filter/select_option_loader.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
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
    required this.filter,
    required this.field,
    required this.delegate,
    required this.options,
    required this.onTap,
  });

  final SelectOptionFilter filter;
  final FieldInfo field;
  final SelectOptionFilterDelegate delegate;
  final List<SelectOptionPB> options;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: options.length,
      separatorBuilder: (context, index) =>
          VSpace(GridSize.typeOptionSeparatorHeight),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = filter.optionIds.contains(option.id);
        return SelectOptionFilterCell(
          option: option,
          isSelected: isSelected,
          onTap: () => _onTapHandler(context, option, isSelected),
        );
      },
    );
  }

  void _onTapHandler(
    BuildContext context,
    SelectOptionPB option,
    bool isSelected,
  ) {
    if (isSelected) {
      final selectedOptionIds = Set<String>.from(filter.optionIds)
        ..remove(option.id);

      _updateSelectOptions(context, filter, selectedOptionIds);
    } else {
      final selectedOptionIds = delegate.selectOption(
        filter.optionIds,
        option.id,
        filter.condition,
      );

      _updateSelectOptions(context, filter, selectedOptionIds);
    }
    onTap();
  }

  void _updateSelectOptions(
    BuildContext context,
    SelectOptionFilter filter,
    Set<String> selectedOptionIds,
  ) {
    final optionIds =
        options.map((e) => e.id).where(selectedOptionIds.contains).toList();
    final newFilter = filter.copyWith(optionIds: optionIds);
    context
        .read<FilterEditorBloc>()
        .add(FilterEditorEvent.updateFilter(newFilter));
  }
}

class SelectOptionFilterCell extends StatelessWidget {
  const SelectOptionFilterCell({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final SelectOptionPB option;
  final bool isSelected;
  final VoidCallback onTap;

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
          option: option,
          onSelected: onTap,
          children: [
            if (isSelected)
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
