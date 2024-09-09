import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/select_option_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/select_option_cell_editor.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/select_option.dart';

class DesktopRowDetailSelectOptionCellSkin
    extends IEditableSelectOptionCellSkin {
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
      onClose: () => cellContainerNotifier.isFocus = false,
      onOpen: () => cellContainerNotifier.isFocus = true,
      popupBuilder: (_) => SelectOptionCellEditor(
        cellController: bloc.cellController,
      ),
      child: BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
        builder: (context, state) {
          return Container(
            alignment: AlignmentDirectional.centerStart,
            padding: state.selectedOptions.isEmpty
                ? const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0)
                : const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
            child: state.selectedOptions.isEmpty
                ? _buildPlaceholder(context)
                : _buildOptions(context, state.selectedOptions),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return FlowyText(
      LocaleKeys.grid_row_textPlaceholder.tr(),
      color: Theme.of(context).hintColor,
    );
  }

  Widget _buildOptions(BuildContext context, List<SelectOptionPB> options) {
    return Wrap(
      runSpacing: 4,
      spacing: 4,
      children: options.map(
        (option) {
          return SelectOptionTag(
            option: option,
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 8,
            ),
          );
        },
      ).toList(),
    );
  }
}
