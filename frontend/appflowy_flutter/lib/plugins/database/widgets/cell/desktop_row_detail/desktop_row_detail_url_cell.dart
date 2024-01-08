import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/url_cell/url_cell_bloc.dart';
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
  ) {
    return TextField(
      controller: textEditingController,
      focusNode: focusNode,
      maxLines: null,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            decoration: TextDecoration.underline,
          ),
      autofocus: false,
      decoration: InputDecoration(
        contentPadding: GridSize.cellContentInsets,
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
      onTapOutside: (_) => focusNode.unfocus(),
    );
  }

  @override
  List<GridCellAccessoryBuilder<State<StatefulWidget>>> accessoryBuilder(
    GridCellAccessoryBuildContext buildContext,
  ) {
    final List<GridCellAccessoryBuilder> accessories = [];
    accessories.addAll(
      cellStyle.accessoryTypes.map((ty) {
        return _accessoryFromType(ty, context);
      }),
    );

    // If the accessories is empty then the default accessory will be GridURLCellAccessoryType.visitURL
    if (accessories.isEmpty) {
      accessories.add(
        _accessoryFromType(
          GridURLCellAccessoryType.visitURL,
          context,
        ),
      );
    }

    return accessories;
  }

  GridCellAccessoryBuilder _accessoryFromType(
    GridURLCellAccessoryType ty,
    GridCellAccessoryBuildContext buildContext,
  ) {
    switch (ty) {
      case GridURLCellAccessoryType.visitURL:
        return VisitURLCellAccessoryBuilder(
          builder: (Key key) => _VisitURLAccessory(
            key: key,
            cellDataNotifier: _cellDataNotifier,
          ),
        );
      case GridURLCellAccessoryType.copyURL:
        return CopyURLCellAccessoryBuilder(
          builder: (Key key) => _CopyURLAccessory(
            key: key,
            cellDataNotifier: _cellDataNotifier,
          ),
        );
    }
  }
}
