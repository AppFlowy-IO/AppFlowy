import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/text_cell/text_cell_bloc.dart';
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
            maxLines: null,
            decoration: InputDecoration(
              contentPadding: GridSize.cellContentInsets,
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
    );
  }
}


// FlowyTextField(
//   controller: _controller,
//   textStyle: widget.cellStyle.textStyle ??
//       Theme.of(context).textTheme.bodyMedium,
//   focusNode: focusNode,
//   autoFocus: widget.cellStyle.autofocus,
//   hintText: widget.cellStyle.placeholder,
//   onChanged: (text) => _cellBloc.add(
//     TextCellEvent.updateText(text),
//   ),
//   debounceDuration: const Duration(milliseconds: 300),
// )