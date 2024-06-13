import 'package:appflowy/plugins/database/application/cell/bloc/summary_cell_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/layout/sizes.dart';
import 'package:appflowy/plugins/database/widgets/cell/editable_cell_skeleton/summary.dart';
import 'package:appflowy/plugins/database/widgets/row/cells/cell_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:styled_widget/styled_widget.dart';

class DesktopGridSummaryCellSkin extends IEditableSummaryCellSkin {
  @override
  Widget build(
    BuildContext context,
    CellContainerNotifier cellContainerNotifier,
    SummaryCellBloc bloc,
    FocusNode focusNode,
    TextEditingController textEditingController,
  ) {
    return ChangeNotifierProvider(
      create: (_) => SummaryMouseNotifier(),
      builder: (context, child) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          opaque: false,
          onEnter: (p) =>
              Provider.of<SummaryMouseNotifier>(context, listen: false)
                  .onEnter = true,
          onExit: (p) =>
              Provider.of<SummaryMouseNotifier>(context, listen: false)
                  .onEnter = false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: GridSize.headerHeight,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Center(
                  child: TextField(
                    controller: textEditingController,
                    enabled: false,
                    focusNode: focusNode,
                    onEditingComplete: () => focusNode.unfocus(),
                    onSubmitted: (_) => focusNode.unfocus(),
                    maxLines: null,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      contentPadding: GridSize.cellContentInsets,
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: GridSize.cellVPadding,
                  ),
                  child: Consumer<SummaryMouseNotifier>(
                    builder: (
                      BuildContext context,
                      SummaryMouseNotifier notifier,
                      Widget? child,
                    ) {
                      if (notifier.onEnter) {
                        return SummaryCellAccessory(
                          viewId: bloc.cellController.viewId,
                          fieldId: bloc.cellController.fieldId,
                          rowId: bloc.cellController.rowId,
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ).positioned(right: 0, bottom: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class SummaryMouseNotifier extends ChangeNotifier {
  SummaryMouseNotifier();

  bool _onEnter = false;

  set onEnter(bool value) {
    if (_onEnter != value) {
      _onEnter = value;
      notifyListeners();
    }
  }

  bool get onEnter => _onEnter;
}
