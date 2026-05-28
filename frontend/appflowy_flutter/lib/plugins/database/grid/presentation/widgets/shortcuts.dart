import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/database/application/row/row_service.dart';
import 'package:appflowy/plugins/database/grid/application/grid_bloc.dart';
import 'package:appflowy/plugins/database/grid/presentation/widgets/selection_controller.dart';
import 'package:appflowy/workspace/presentation/widgets/dialogs.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class GridShortcuts extends StatelessWidget {
  const GridShortcuts({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.delete): () => _deleteSelectedRows(context),
        const SingleActivator(LogicalKeyboardKey.backspace): () => _deleteSelectedRows(context),
        const SingleActivator(LogicalKeyboardKey.escape): () => _clearSelection(context),
        const SingleActivator(LogicalKeyboardKey.keyA, control: true): () => _selectAllRows(context),
        const SingleActivator(LogicalKeyboardKey.keyA, meta: true): () => _selectAllRows(context),
      },
      child: child,
    );
  }

  void _deleteSelectedRows(BuildContext context) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus != null && primaryFocus.context != null) {
      bool isTextInputFocused = false;
      primaryFocus.context!.visitAncestorElements((element) {
        if (element.widget is EditableText || element.widget is TextField) {
          isTextInputFocused = true;
          return false;
        }
        return true;
      });
      if (isTextInputFocused) return;
    }

    final selection = context.read<GridSelectionController>();
    if (selection.hasSelection) {
      final selectedIds = selection.selectedRowIds.toList();
      final viewId = context.read<GridBloc>().viewId;

      showConfirmDeletionDialog(
        context: context,
        name: LocaleKeys.grid_row_label.tr(),
        description: LocaleKeys.grid_row_deleteRowPrompt.tr(),
        onConfirm: () {
          RowBackendService.deleteRows(viewId, selectedIds);
          selection.clearSelection();
        },
      );
    }
  }

  void _clearSelection(BuildContext context) {
    context.read<GridSelectionController>().clearSelection();
  }

  void _selectAllRows(BuildContext context) {
    context.read<GridSelectionController>().selectAll();
  }
}
