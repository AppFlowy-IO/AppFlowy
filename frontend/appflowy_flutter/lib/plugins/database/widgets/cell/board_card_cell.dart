import 'package:appflowy/plugins/database/application/cell/cell_controller.dart';
import 'package:appflowy/plugins/database/application/database_controller.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/protobuf.dart';
import 'package:appflowy_popover/appflowy_popover.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'editable_cell_builder.dart';

/// A stable keyboard target even while a card field switches editor widgets.
class BoardCardFocusNode extends FocusNode {
  BoardCardFocusNode({super.debugLabel}) : super(skipTraversal: true);

  VoidCallback? onRequestEditing;

  void startEditing() {
    requestFocus();
    onRequestEditing?.call();
  }
}

/// Uses the existing cell editor when a property on a board card is clicked.
class BoardCardCell extends StatefulWidget {
  const BoardCardCell({
    super.key,
    required this.databaseController,
    required this.cellContext,
    required this.fieldType,
    required this.fieldName,
    required this.child,
    this.onShiftTap,
    this.isCardEditing = false,
    this.focusNode,
  });

  final DatabaseController databaseController;
  final CellContext cellContext;
  final FieldType fieldType;
  final String fieldName;
  final Widget child;
  final VoidCallback? onShiftTap;
  final bool isCardEditing;
  final BoardCardFocusNode? focusNode;

  static bool canEdit(FieldType fieldType) => switch (fieldType) {
        FieldType.RichText ||
        FieldType.Number ||
        FieldType.DateTime ||
        FieldType.SingleSelect ||
        FieldType.MultiSelect ||
        FieldType.URL ||
        FieldType.Checklist ||
        FieldType.Relation ||
        FieldType.Time ||
        FieldType.Media =>
          true,
        _ => false,
      };

  @override
  State<BoardCardCell> createState() => _BoardCardCellState();
}

class _BoardCardCellState extends State<BoardCardCell> {
  EditableCellWidget? _editor;
  bool _openingEditor = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.onRequestEditing = _startEditingFromKeyboard;
  }

  void _startEditingFromKeyboard() {
    if (widget.isCardEditing) {
      _startEditing(fromKeyboard: true);
      Scrollable.ensureVisible(context);
    }
  }

  void _unbindFocusNode(BoardCardFocusNode? node) {
    // A field-type change can mount its new editor before disposing the old
    // one. Only remove the callback belonging to this cell instance.
    if (node?.onRequestEditing == _startEditingFromKeyboard) {
      node?.onRequestEditing = null;
    }
  }

  void _startEditing({bool fromKeyboard = false}) {
    if (!fromKeyboard && HardwareKeyboard.instance.isShiftPressed) {
      widget.onShiftTap?.call();
      return;
    }
    if (_editor != null) {
      _editor!.requestFocus.notify();
      return;
    }

    final EditableCellStyle style = widget.fieldType == FieldType.Checklist ||
            widget.fieldType == FieldType.Media
        ? EditableCellStyle.desktopGrid
        : EditableCellStyle.desktopRowDetail;
    final EditableCellWidget editor = EditableCellBuilder(
      databaseController: widget.databaseController,
    ).buildStyled(widget.cellContext, style);

    _openingEditor = true;
    editor.cellContainerNotifier.addListener(_onFocusChanged);
    setState(() => _editor = editor);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _editor != editor) {
        return;
      }
      // Some popover editors only notify when they close. Mark them active
      // after mounting, so a text editor's initial unfocused state is ignored.
      editor
        ..requestFocus.notify()
        ..cellContainerNotifier.isFocus = true;
      _openingEditor = false;
    });
  }

  void _onFocusChanged() {
    if (!_openingEditor && !(_editor?.cellContainerNotifier.isFocus ?? true)) {
      _editor?.cellContainerNotifier.removeListener(_onFocusChanged);
      setState(() => _editor = null);
    }
  }

  @override
  void didUpdateWidget(covariant BoardCardCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _unbindFocusNode(oldWidget.focusNode);
      widget.focusNode?.onRequestEditing = _startEditingFromKeyboard;
    }
    if (oldWidget.isCardEditing && !widget.isCardEditing) {
      _editor?.cellContainerNotifier.removeListener(_onFocusChanged);
      _editor = null;
      _openingEditor = false;
    }
  }

  @override
  void dispose() {
    _unbindFocusNode(widget.focusNode);
    _editor?.cellContainerNotifier.removeListener(_onFocusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final GestureDetector child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _startEditing(),
      child: _buildCell(),
    );
    final BoardCardFocusNode? focusNode = widget.focusNode;
    return focusNode == null
        ? child
        : PopoverFocusScope(
            parentNode: focusNode,
            child: Focus(
              focusNode: focusNode,
              skipTraversal: true,
              child: child,
            ),
          );
  }

  Widget _buildCell() {
    final EditableCellWidget? editor = _editor;
    if (editor != null) {
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): () =>
              FocusManager.instance.primaryFocus?.unfocus(),
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              FocusManager.instance.primaryFocus?.unfocus(),
        },
        child: editor,
      );
    }

    final MouseRegion child = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: widget.child,
    );
    // A tooltip can cover another property as the card expands for editing.
    // Keep field names accessible without an overlay during the edit session.
    return widget.isCardEditing
        ? Semantics(label: widget.fieldName, child: child)
        : Tooltip(message: widget.fieldName, child: child);
  }
}
