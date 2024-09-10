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
          const _IconOrEmoji(),
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

class _IconOrEmoji extends StatelessWidget {
  const _IconOrEmoji();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TextCellBloc, TextCellState>(
      builder: (context, state) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.emoji != null)
              ValueListenableBuilder<String>(
                valueListenable: state.emoji!,
                builder: (context, value, child) {
                  if (value.isEmpty) {
                    return const SizedBox.shrink();
                  } else {
                    return FlowyText(
                      value,
                      fontSize: 16,
                    );
                  }
                },
              ),
            if (state.hasDocument != null)
              ValueListenableBuilder<bool>(
                valueListenable: state.hasDocument!,
                builder: (context, hasDocument, child) {
                  if ((state.emoji?.value.isEmpty ?? true) && hasDocument) {
                    return FlowySvg(
                      FlowySvgs.notes_s,
                      color: Theme.of(context).hintColor,
                    );
                  } else {
                    return const SizedBox.shrink();
                  }
                },
              ),
            const HSpace(6),
          ],
        );
      },
    );
  }
}
