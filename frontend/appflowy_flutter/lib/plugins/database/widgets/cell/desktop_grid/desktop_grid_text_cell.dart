import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/text.dart';

class DesktopGridTextCellSkin extends IEditableTextCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TextCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
    return Padding(
      padding: GridSize.cellContentInsets,
      child: Row(
        children: [
          BlocBuilder<TextCellBloc, TextCellState>(
            buildWhen: (p, c) => p.emoji != c.emoji,
            builder: (context, state) {
              if (state.emoji.isNotEmpty) {
                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlowyText(
                        state.emoji,
                        fontSize: 16,
                      ),
                      const HSpace(6),
                    ],
                  ),
                );
              }

              if (state.hasDocument) {
                return Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FlowySvg(
                        FlowySvgs.notes_s,
                        color: Theme.of(context).hintColor,
                      ),
                      const HSpace(6),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: TextField(
              controller: textEditingController,
              focusNode: focusNode,
              maxLines: context.watch<TextCellBloc>().state.wrap ? null : 1,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: const InputDecoration(
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                isDense: true,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
