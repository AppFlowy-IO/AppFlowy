import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/text_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/text.dart';

class MobileRowDetailTextCellSkin extends IEditableTextCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    TextCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
    return TextField(
      controller: textEditingController,
      focusNode: focusNode,
      maxLines: null,
      decoration: InputDecoration(
        enabledBorder:
            _getInputBorder(color: Theme.of(context).colorScheme.outline),
        focusedBorder:
            _getInputBorder(color: Theme.of(context).colorScheme.primary),
        hintText: LocaleKeys.grid_row_textPlaceholder.tr(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        isCollapsed: true,
        isDense: true,
        constraints: const BoxConstraints(minHeight: 48),
        hintStyle: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).hintColor),
      ),
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
    );
  }

  InputBorder _getInputBorder({Color? color}) {
    return OutlineInputBorder(
      borderSide: BorderSide(color: color!),
      borderRadius: const BorderRadius.all(Radius.circular(14)),
      gapPadding: 0,
    );
  }
}
