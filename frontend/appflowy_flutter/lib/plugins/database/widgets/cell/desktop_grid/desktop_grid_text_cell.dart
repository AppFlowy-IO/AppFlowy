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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _IconOrEmoji(),
          Expanded(
            child: TextField(
              controller: textEditingController,
              focusNode: focusNode,
              maxLines: context.watch<TextCellBloc>().state.wrap ? null : 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: context
                            .read<TextCellBloc>()
                            .cellController
                            .fieldInfo
                            .isPrimary
                        ? FontWeight.w500
                        : null,
                  ),
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
        // if not a title cell, return empty widget
        if (state.emoji == null || state.hasDocument == null) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<String>(
          valueListenable: state.emoji!,
          builder: (context, emoji, _) {
            return emoji.isNotEmpty
                ? Padding(
                    padding: const EdgeInsetsDirectional.only(end: 6.0),
                    child: FlowyText.emoji(
                      optimizeEmojiAlign: true,
                      emoji,
                    ),
                  )
                : ValueListenableBuilder<bool>(
                    valueListenable: state.hasDocument!,
                    builder: (context, hasDocument, _) {
                      return hasDocument
                          ? Padding(
                              padding:
                                  const EdgeInsetsDirectional.only(end: 6.0)
                                      .add(const EdgeInsets.all(1)),
                              child: FlowySvg(
                                FlowySvgs.notes_s,
                                color: Theme.of(context).hintColor,
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  );
          },
        );
      },
    );
  }
}
