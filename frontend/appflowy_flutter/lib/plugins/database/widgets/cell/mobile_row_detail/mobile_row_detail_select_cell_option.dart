import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/mobile_select_option_editor.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/select_option_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/select_option.dart';

class MobileRowDetailSelectOptionCellSkin
    extends IEditableSelectOptionCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    SelectOptionCellBloc bloc,
    PopoverController popoverController,
  ) {
    return BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
      builder: (context, state) {
        return InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          onTap: () => showMobileBottomSheet(
            context,
            builder: (context) {
              return MobileSelectOptionEditor(
                cellController: bloc.cellController,
              );
            },
          ),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 48,
              minWidth: double.infinity,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: state.selectedOptions.isEmpty ? 13 : 10,
            ),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: state.selectedOptions.isEmpty
                      ? _buildPlaceholder(context)
                      : _buildOptions(context, state.selectedOptions),
                ),
                const HSpace(6),
                RotatedBox(
                  quarterTurns: 3,
                  child: Icon(
                    Icons.chevron_left,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const HSpace(2),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: FlowyText(
        LocaleKeys.grid_row_textPlaceholder.tr(),
        color: Theme.of(context).hintColor,
      ),
    );
  }

  Widget _buildOptions(BuildContext context, List<SelectOptionPB> options) {
    final children = options.mapIndexed(
      (index, option) {
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
          child: SelectOptionTag(
            option: option,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          ),
        );
      },
    ).toList();

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Wrap(
        runSpacing: 4,
        children: children,
      ),
    );
  }
}
