import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/database/application/cell/bloc/url_cell_bloc.dart';
import 'package:appflowy/plugins/database/widgets/row/accessory/cell_accessory.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:flowy_infra/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../editable_cell_skeleton/url.dart';

class MobileGridURLCellSkin extends IEditableURLCellSkin {
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
        return GestureDetector(
          onTap: () => _showURLEditor(context, bloc, textEditingController),
          behavior: HitTestBehavior.opaque,
          child: Container(
            alignment: AlignmentDirectional.centerStart,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                content,
                maxLines: 1,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      decoration: TextDecoration.underline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showURLEditor(
    BuildContext context,
    URLCellBloc bloc,
    TextEditingController textEditingController,
  ) {
    showMobileBottomSheet(
      context,
      showDragHandle: true,
      backgroundColor: AFThemeExtension.of(context).background,
      builder: (context) => BlocProvider.value(
        value: bloc,
        child: MobileURLEditor(
          textEditingController: textEditingController,
        ),
      ),
    );
  }

  @override
  List<GridCellAccessoryBuilder<State<StatefulWidget>>> accessoryBuilder(
    GridCellAccessoryBuildContext context,
    URLCellDataNotifier cellDataNotifier,
  ) =>
      const [];
}
