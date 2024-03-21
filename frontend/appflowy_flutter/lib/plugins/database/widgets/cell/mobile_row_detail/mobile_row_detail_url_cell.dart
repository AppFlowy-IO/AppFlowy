import 'package:flutter/material.dart';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/url_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/url.dart';

class MobileRowDetailURLCellSkin extends IEditableURLCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    URLCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
    URLCellDataNotifier cellDataNotifier,
  ) {
    return BlocSelector<URLCellBloc, URLCellState, String>(
      selector: (state) => state.content,
      builder: (context, content) {
        return InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(14)),
          onTap: () => showMobileBottomSheet(
            context,
            showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.background,
            builder: (_) {
              return BlocProvider.value(
                value: bloc,
                child: MobileURLEditor(
                  textEditingController: textEditingController,
                ),
              );
            },
          ),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 48,
              minWidth: double.infinity,
            ),
            decoration: BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              borderRadius: const BorderRadius.all(Radius.circular(14)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Text(
                content.isEmpty
                    ? LocaleKeys.grid_row_textPlaceholder.tr()
                    : content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      decoration:
                          content.isEmpty ? null : TextDecoration.underline,
                      color: content.isEmpty
                          ? Theme.of(context).hintColor
                          : Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  List<GridCellAccessoryBuilder<State<StatefulWidget>>> accessoryBuilder(
    GridCellAccessoryBuildContext context,
    URLCellDataNotifier cellDataNotifier,
  ) =>
      const [];
}
