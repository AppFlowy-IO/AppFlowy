import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/number_cell_bloc.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/number.dart';

class MobileGridNumberCellSkin extends IEditableNumberCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    NumberCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
    return TextField(
      controller: textEditingController,
      focusNode: focusNode,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15),
      decoration: const InputDecoration(
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        isCollapsed: true,
      ),
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  }
}
