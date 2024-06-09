import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/text.dart';

class MobileGridTextCellSkin extends IEditableTextCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TextCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
    return Row(
      children: [
        BlocBuilder<TextCellBloc, TextCellState>(
          buildWhen: (p, c) => p.emoji != c.emoji,
          builder: (context, state) => Center(
            child: FlowyText(
              state.emoji,
              fontSize: 16,
            ),
          ),
        ),
        const HSpace(6),
        Expanded(
          child: TextField(
            controller: textEditingController,
            focusNode: focusNode,
            style:
                Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
            decoration: const InputDecoration(
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              isCollapsed: true,
            ),
            onTapOutside: (event) => focusNode.unfocus(),
          ),
        ),
      ],
    );
  }
}
