import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/extension.dart';
import 'package:appflowy/plugins/database/widgets/cell_editor/mobile_select_option_editor.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/select_option_cell_bloc.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/select_option_entities.pb.dart';
import 'package:collection/collection.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/select_option.dart';

class MobileGridSelectOptionCellSkin extends IEditableSelectOptionCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    SelectOptionCellBloc bloc,
    PopoverController popoverController,
  ) {
    return BlocBuilder<SelectOptionCellBloc, SelectOptionCellState>(
      builder: (context, state) {
        return FlowyButton(
          hoverColor: Colors.transparent,
          radius: BorderRadius.zero,
          margin: EdgeInsets.zero,
          text: Align(
            alignment: AlignmentDirectional.centerStart,
            child: state.selectedOptions.isEmpty
                ? const SizedBox.shrink()
                : _buildOptions(context, state.selectedOptions),
          ),
          onTap: () {
            showMobileBottomSheet(
              context,
              builder: (context) {
                return MobileSelectOptionEditor(
                  cellController: bloc.cellController,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildOptions(BuildContext context, List<SelectOptionPB> options) {
    final children = options
        .mapIndexed(
          (index, option) => SelectOptionTag(
            option: option,
            fontSize: 14,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
        )
        .toList();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      separatorBuilder: (context, index) => const HSpace(8),
      itemCount: children.length,
      itemBuilder: (context, index) => children[index],
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    );
  }
}
