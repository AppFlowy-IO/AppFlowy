import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

const enableTableDebugLog = false;

class SimpleTableContext {
  SimpleTableContext() {
    if (enableTableDebugLog) {
      isHoveringOnColumnsAndRows.addListener(
        _onHoveringOnColumnsAndRowsChanged,
      );
      isHoveringOnTableArea.addListener(
        _onHoveringOnTableAreaChanged,
      );
      hoveringTableCell.addListener(_onHoveringTableNodeChanged);
      selectingColumn.addListener(_onSelectingColumnChanged);
      selectingRow.addListener(_onSelectingRowChanged);
      isSelectingTable.addListener(_onSelectingTableChanged);
      isHoveringOnTableBlock.addListener(_onHoveringOnTableBlockChanged);
    }
  }

  // the area only contains the columns and rows,
  //  the add row button, add column button, and add column and row button are not part of the table area
  final ValueNotifier<bool> isHoveringOnColumnsAndRows = ValueNotifier(false);

  // the table area contains the columns and rows,
  //  the add row button, add column button, and add column and row button are not part of the table area,
  //  not including the selection area and padding
  final ValueNotifier<bool> isHoveringOnTableArea = ValueNotifier(false);

  // the table block area contains the table area and the add row button, add column button, and add column and row button
  //  also, the table block area contains the selection area and padding
  final ValueNotifier<bool> isHoveringOnTableBlock = ValueNotifier(false);

  // the hovering table cell is the cell that the mouse is hovering on
  final ValueNotifier<Node?> hoveringTableCell = ValueNotifier(null);

  // the hovering on resize handle is the resize handle that the mouse is hovering on
  final ValueNotifier<Node?> hoveringOnResizeHandle = ValueNotifier(null);

  // the selecting column is the column that the user is selecting
  final ValueNotifier<int?> selectingColumn = ValueNotifier(null);

  // the selecting row is the row that the user is selecting
  final ValueNotifier<int?> selectingRow = ValueNotifier(null);

  // the is selecting table is the table that the user is selecting
  final ValueNotifier<bool> isSelectingTable = ValueNotifier(false);

  void _onHoveringOnColumnsAndRowsChanged() {
    if (!enableTableDebugLog) {
      return;
    }

    Log.debug('isHoveringOnTable: ${isHoveringOnColumnsAndRows.value}');
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

  void _onHoveringOnTableAreaChanged() {
    if (!enableTableDebugLog) {
      return;
    }

    Log.debug('isHoveringOnTableArea: ${isHoveringOnTableArea.value}');
  }

  void dispose() {
    isHoveringOnColumnsAndRows.dispose();
    isHoveringOnTableBlock.dispose();
    isHoveringOnTableArea.dispose();
    hoveringTableCell.dispose();
    hoveringOnResizeHandle.dispose();
    selectingColumn.dispose();
    selectingRow.dispose();
    isSelectingTable.dispose();
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
    // don't add padding to the top of the table, the first row will have padding
    //  to make the column action button clickable.
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
  static EdgeInsets get cellEdgePadding => UniversalPlatform.isDesktop
      ? const EdgeInsets.symmetric(
          horizontal: 9.0,
          vertical: 2.0,
        )
      : const EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          bottom: 6.0,
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
