import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/widgets/cell/desktop_grid/desktop_grid_url_cell.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/url_cell_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../editable_cell_skeleton/url.dart';

class DesktopRowDetailURLSkin extends IEditableURLCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    URLCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    URLCellDataNotifier cellDataNotifier,
  ) {
    return TextField(
      controller: textEditingController,
      focusNode: focusNode,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        hintText: LocaleKeys.grid_row_textPlaceholder.tr(),
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
        isDense: true,
      ),
    );
  }

  @override
  List<GridCellAccessoryBuilder> accessoryBuilder(
    GridCellAccessoryBuildContext context,
    URLCellDataNotifier cellDataNotifier,
  ) {
    return [
      accessoryFromType(
        GridURLCellAccessoryType.visitURL,
        cellDataNotifier,
      ),
    ];
  }
}
