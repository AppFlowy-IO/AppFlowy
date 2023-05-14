import 'package:appflowy/plugins/database_view/grid/presentation/widgets/header/type_option/select_option_editor.dart';
import 'package:appflowy/plugins/database_view/widgets/row/cells/select_option_cell/extension.dart';
import 'package:appflowy/workspace/presentation/widgets/pop_up_action.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/image.dart';
import 'package:flutter/material.dart';

enum OptionAction {
  delete,
  duplicate,
  turnInto,
  moveUp,
  moveDown,
  color,
  divider,
}

class DividerOptionAction extends CustomActionCell {
  @override
  Widget buildWithContext(BuildContext context) {
    return const Divider(
      height: 1.0,
    );
  }
}

class ColorOptionAction extends PopoverActionCell {
  ColorOptionAction({
    required this.editorState,
  });

  final EditorState editorState;

  @override
  Widget? leftIcon(Color iconColor) {
    return svgWidget(
      'editor/color', // todo: add color icon
      color: iconColor,
    );
  }

  @override
  String get name {
    return 'Color';
  }

  @override
  WidgetBuilder get builder => (context) => SelectOptionColorList(
        selectedColor: SelectOptionColorPB.Blue,
        onSelectedColor: (color) {
          final selection = editorState.selection;
          if (selection == null) {
            return;
          }
          final nodes = editorState.getNodesInSelection(selection);
          final transaction = editorState.transaction;
          for (final node in nodes) {
            transaction.updateNode(node, {
              'bgColor': color.make(context).toHex(),
            });
          }
          editorState.apply(transaction);
        },
      );
}

class OptionActionWrapper extends ActionCell {
  final OptionAction inner;

  OptionActionWrapper(this.inner);

  @override
  Widget? leftIcon(Color iconColor) {
    var name = '';
    // TODO: add icons.
    switch (inner) {
      case OptionAction.delete:
        name = 'editor/delete';
        break;
      case OptionAction.duplicate:
        name = 'editor/duplicate';
        break;
      case OptionAction.turnInto:
        name = 'editor/turn_into';
        break;
      case OptionAction.moveUp:
        name = 'editor/move_up';
        break;
      case OptionAction.moveDown:
        name = 'editor/move_down';
        break;
      case OptionAction.color:
        name = 'editor/color';
        break;
      case OptionAction.divider:
        throw UnimplementedError();
    }
    if (name.isEmpty) {
      return null;
    }
    name = 'editor/delete';
    return svgWidget(
      name,
      color: iconColor,
    );
  }

  @override
  String get name {
    var description = '';
    switch (inner) {
      // TODO: l10n
      case OptionAction.delete:
        description = 'Delete';
        break;
      case OptionAction.duplicate:
        description = 'Duplicate';
        break;
      case OptionAction.turnInto:
        description = 'Turn into';
        break;
      case OptionAction.moveUp:
        description = 'Move up';
        break;
      case OptionAction.moveDown:
        description = 'Move down';
        break;
      case OptionAction.color:
        description = 'Color';
        break;
      case OptionAction.divider:
        throw UnimplementedError();
    }
    return description;
  }
}
