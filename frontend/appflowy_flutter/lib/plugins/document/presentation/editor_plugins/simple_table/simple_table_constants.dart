import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

const enableTableDebugLog = false;

class SimpleTableContext {
  SimpleTableContext() {
    if (enableTableDebugLog) {
      isHoveringOnTable.addListener(_onHoveringOnTableChanged);
      hoveringTableCell.addListener(_onHoveringTableNodeChanged);
      selectingColumn.addListener(_onSelectingColumnChanged);
      selectingRow.addListener(_onSelectingRowChanged);
      isSelectingTable.addListener(_onSelectingTableChanged);
      isHoveringOnTableBlock.addListener(_onHoveringOnTableBlockChanged);
    }
  }

  final ValueNotifier<bool> isHoveringOnTable = ValueNotifier(false);
  final ValueNotifier<Node?> hoveringTableCell = ValueNotifier(null);
  final ValueNotifier<Node?> hoveringOnResizeHandle = ValueNotifier(null);
  final ValueNotifier<int?> selectingColumn = ValueNotifier(null);
  final ValueNotifier<int?> selectingRow = ValueNotifier(null);
  final ValueNotifier<bool> isSelectingTable = ValueNotifier(false);
  final ValueNotifier<bool> isHoveringOnTableBlock = ValueNotifier(false);

  void _onHoveringOnTableChanged() {
    if (!enableTableDebugLog) {
      return;
    }

    Log.debug('isHoveringOnTable: ${isHoveringOnTable.value}');
  }

  void _onHoveringTableNodeChanged() {
    if (!enableTableDebugLog) {
      return;
    }

    final node = hoveringTableCell.value;
    if (node == null) {
      return;
    }

    Log.debug('hoveringTableNode: $node, ${node.cellPosition}');
  }

  void _onSelectingColumnChanged() {
    if (!enableTableDebugLog) {
      return;
    }

    Log.debug('selectingColumn: ${selectingColumn.value}');
  }

  void _onSelectingRowChanged() {
    if (!enableTableDebugLog) {
      return;
    }

    Log.debug('selectingRow: ${selectingRow.value}');
  }

  void _onSelectingTableChanged() {
    if (!enableTableDebugLog) {
      return;
    }

    Log.debug('isSelectingTable: ${isSelectingTable.value}');
  }

  void _onHoveringOnTableBlockChanged() {
    if (!enableTableDebugLog) {
      return;
    }

    Log.debug('isHoveringOnTableBlock: ${isHoveringOnTableBlock.value}');
  }

  void dispose() {
    isHoveringOnTable.dispose();
    hoveringTableCell.dispose();
    hoveringOnResizeHandle.dispose();
    selectingColumn.dispose();
    selectingRow.dispose();
    isSelectingTable.dispose();
    isHoveringOnTableBlock.dispose();
  }
}

class SimpleTableConstants {
  // Table
  static const defaultColumnWidth = 120.0;
  static const minimumColumnWidth = 36.0;

  static const tableTopPadding = 8.0;
  static const tableLeftPadding = 8.0;

  static const tableBottomPadding =
      addRowButtonHeight + 3 * addRowButtonPadding;
  static const tableRightPadding =
      addColumnButtonWidth + 2 * SimpleTableConstants.addColumnButtonPadding;

  static const tablePadding = EdgeInsets.only(
    top: tableTopPadding,
    bottom: tableBottomPadding,
    left: tableLeftPadding,
    right: tableRightPadding,
  );

  // Add row button
  static const addRowButtonHeight = 16.0;
  static const addRowButtonPadding = 4.0;
  static const addRowButtonRadius = 4.0;
  static const addRowButtonRightPadding =
      addColumnButtonWidth + addColumnButtonPadding * 2;

  // Add column button
  static const addColumnButtonWidth = 16.0;
  static const addColumnButtonPadding = 2.0;
  static const addColumnButtonRadius = 4.0;
  static const addColumnButtonBottomPadding =
      addRowButtonHeight + 3 * addRowButtonPadding;

  // Add column and row button
  static const addColumnAndRowButtonWidth = addColumnButtonWidth;
  static const addColumnAndRowButtonHeight = addRowButtonHeight;
  static const addColumnAndRowButtonCornerRadius = addColumnButtonWidth / 2.0;
  static const addColumnAndRowButtonBottomPadding = 2.5 * addRowButtonPadding;

  // Table cell
  static const cellEdgePadding = EdgeInsets.symmetric(
    horizontal: 9.0,
    vertical: 2.0,
  );
  static const cellBorderWidth = 1.0;
  static const resizeHandleWidth = 3.0;

  static const borderType = SimpleTableBorderRenderType.cell;

  // Table more action
  static const moreActionHeight = 34.0;
  static const moreActionPadding = EdgeInsets.symmetric(vertical: 2.0);
  static const moreActionHorizontalMargin =
      EdgeInsets.symmetric(horizontal: 6.0);
}

enum SimpleTableBorderRenderType {
  cell,
  table,
}

extension SimpleTableColors on BuildContext {
  Color get simpleTableBorderColor => Theme.of(this).isLightMode
      ? const Color(0xFFE4E5E5)
      : const Color(0xFF3A3F49);

  Color get simpleTableDividerColor => Theme.of(this).isLightMode
      ? const Color(0x141F2329)
      : const Color(0xFF23262B).withOpacity(0.5);

  Color get simpleTableMoreActionBackgroundColor => Theme.of(this).isLightMode
      ? const Color(0xFFF2F3F5)
      : const Color(0xFF2D3036);

  Color get simpleTableMoreActionBorderColor => Theme.of(this).isLightMode
      ? const Color(0xFFCFD3D9)
      : const Color(0xFF44484E);

  Color get simpleTableMoreActionHoverColor => Theme.of(this).isLightMode
      ? const Color(0xFF00C8FF)
      : const Color(0xFF00C8FF);

  Color get simpleTableDefaultHeaderColor => Theme.of(this).isLightMode
      ? const Color(0xFFF2F2F2)
      : const Color(0x08FFFFFF);
}
