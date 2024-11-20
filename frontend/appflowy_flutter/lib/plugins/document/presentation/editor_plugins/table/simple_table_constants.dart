import 'package:appflowy/plugins/document/presentation/editor_plugins/table/table_operations.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class SimpleTableContext {
  SimpleTableContext() {
    isHoveringOnTable.addListener(_onHoveringOnTableChanged);
    hoveringTableNode.addListener(_onHoveringTableNodeChanged);
  }

  final ValueNotifier<bool> isHoveringOnTable = ValueNotifier(false);
  final ValueNotifier<Node?> hoveringTableNode = ValueNotifier(null);

  void _onHoveringOnTableChanged() {
    debugPrint('isHoveringOnTable: ${isHoveringOnTable.value}');
  }

  void _onHoveringTableNodeChanged() {
    final node = hoveringTableNode.value;
    if (node == null) {
      return;
    }

    debugPrint('hoveringTableNode: $node, ${node.cellPosition}');
  }

  void dispose() {
    isHoveringOnTable.dispose();
    hoveringTableNode.dispose();
  }
}

class SimpleTableConstants {
  static const defaultColumnWidth = 120.0;
  static const minimumColumnWidth = 50.0;
  static const borderColor = Color(0xFFE4E5E5);

  static const tableTopPadding = 8.0;
  static const tableLeftPadding = 8.0;

  static const addRowButtonHeight = 16.0;
  static const addRowButtonPadding = 2.0;
  static const addRowButtonBackgroundColor = Color(0xFFF2F3F5);
  static const addRowButtonRadius = 4.0;
  static const addRowButtonRightPadding =
      addColumnButtonWidth + addColumnButtonPadding * 2;

  static const addColumnButtonWidth = 16.0;
  static const addColumnButtonPadding = 2.0;
  static const addColumnButtonBackgroundColor = addRowButtonBackgroundColor;
  static const addColumnButtonRadius = 4.0;
  static const addColumnButtonBottomPadding =
      addRowButtonHeight + addRowButtonPadding * 2;

  static const addColumnAndRowButtonWidth = addColumnButtonWidth;
  static const addColumnAndRowButtonHeight = addRowButtonHeight;
  static const addColumnAndRowButtonCornerRadius = addColumnButtonWidth / 2.0;
  static const addColumnAndRowButtonBackgroundColor =
      addColumnButtonBackgroundColor;

  static const cellEdgePadding = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 2.0,
  );

  static const borderType = SimpleTableBorderRenderType.table;
}

enum SimpleTableBorderRenderType {
  cell,
  table,
}
