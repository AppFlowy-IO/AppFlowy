import 'package:appflowy/plugins/database/application/cell/bloc/select_option_cell_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/select_option_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/select_option.dart';

class DesktopGridSelectOptionCellSkin extends IEditableSelectOptionCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    SelectOptionCellBloc bloc,
    PopoverController popoverController,
  ) {
    return AppFlowyPopover(
      controller: popoverController,
      constraints: const BoxConstraints.tightFor(width: 300),
      margin: EdgeInsets.zero,
      triggerActions: PopoverTriggerFlags.none,
      direction: PopoverDirection.bottomWithLeftAligned,
      popupBuilder: (BuildContext popoverContext) {
        return SelectOptionCellEditor(
          cellController: bloc.cellController,
        );
      },
      onClose: () => cellContainerNotifier.isFocus = false,
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        builder: (context, state) {
          return Align(
            alignment: AlignmentDirectional.centerStart,
            child: state.wrap
                ? _buildWrapOptions(context, state.selectedOptions)
                : _buildNoWrapOptions(context, state.selectedOptions),
          );
        },
      ),
    );
  }

  Widget _buildWrapOptions(BuildContext context, List<SelectOptionPB> options) {
    return Padding(
      padding: GridSize.cellContentInsets,
      child: Wrap(
        runSpacing: 4,
        children: options.map(
          (option) {
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: SelectOptionTag(
                option: option,
                padding: const EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  Widget _buildNoWrapOptions(
    BuildContext context,
    List<SelectOptionPB> options,
  ) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: GridSize.cellContentInsets,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: options.map(
            (option) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: SelectOptionTag(
                  option: option,
                  padding: const EdgeInsets.symmetric(
                    vertical: 1,
                    horizontal: 8,
                  ),
                ),
              );
            },
          ).toList(),
        ),
      ),
    );
  }
}
