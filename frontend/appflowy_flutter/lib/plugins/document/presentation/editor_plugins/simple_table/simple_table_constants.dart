import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/plugins/document/presentation/editor_style.dart';
import 'package:appflowy/util/theme_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:universal_platform/universal_platform.dart';

const _enableTableDebugLog = false;

class SimpleTableContext {
  SimpleTableContext() {
    if (_enableTableDebugLog) {
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
      isReorderingColumn.addListener(_onDraggingColumnChanged);
      isReorderingRow.addListener(_onDraggingRowChanged);
    }
  }

  /// the area only contains the columns and rows,
  ///  the add row button, add column button, and add column and row button are not part of the table area
  final ValueNotifier<bool> isHoveringOnColumnsAndRows = ValueNotifier(false);

  /// the table area contains the columns and rows,
  ///  the add row button, add column button, and add column and row button are not part of the table area,
  ///  not including the selection area and padding
  final ValueNotifier<bool> isHoveringOnTableArea = ValueNotifier(false);

  /// the table block area contains the table area and the add row button, add column button, and add column and row button
  ///  also, the table block area contains the selection area and padding
  final ValueNotifier<bool> isHoveringOnTableBlock = ValueNotifier(false);

  /// the hovering table cell is the cell that the mouse is hovering on
  final ValueNotifier<Node?> hoveringTableCell = ValueNotifier(null);

  /// the hovering on resize handle is the resize handle that the mouse is hovering on
  final ValueNotifier<Node?> hoveringOnResizeHandle = ValueNotifier(null);

  /// the selecting column is the column that the user is selecting
  final ValueNotifier<int?> selectingColumn = ValueNotifier(null);

  /// the selecting row is the row that the user is selecting
  final ValueNotifier<int?> selectingRow = ValueNotifier(null);

  /// the is selecting table is the table that the user is selecting
  final ValueNotifier<bool> isSelectingTable = ValueNotifier(false);

  /// isReorderingColumn is a tuple of (isReordering, columnIndex)
  final ValueNotifier<(bool, int)> isReorderingColumn =
      ValueNotifier((false, -1));

  /// isReorderingRow is a tuple of (isReordering, rowIndex)
  final ValueNotifier<(bool, int)> isReorderingRow = ValueNotifier((false, -1));

  /// reorderingOffset is the offset of the reordering
  //
  /// This value is only available when isReordering is true
  final ValueNotifier<Offset> reorderingOffset = ValueNotifier(Offset.zero);

  /// isDraggingRow to expand the rows of the table
  bool isDraggingRow = false;

  /// isDraggingColumn to expand the columns of the table
  bool isDraggingColumn = false;

  bool get isReordering =>
      isReorderingColumn.value.$1 || isReorderingRow.value.$1;

  /// isEditingCell is the cell that the user is editing
  ///
  /// This value is available on mobile only
  final ValueNotifier<Node?> isEditingCell = ValueNotifier(null);

  /// isReorderingHitCell is the cell that the user is reordering
  ///
  /// This value is available on mobile only
  final ValueNotifier<int?> isReorderingHitIndex = ValueNotifier(null);

  void _onHoveringOnColumnsAndRowsChanged() {
    if (!_enableTableDebugLog) {
      return;
    }

    Log.debug('isHoveringOnTable: ${isHoveringOnColumnsAndRows.value}');
  }

  void _onHoveringTableNodeChanged() {
    if (!_enableTableDebugLog) {
      return;
    }

    final node = hoveringTableCell.value;
    if (node == null) {
      return;
    }

    Log.debug('hoveringTableNode: $node, ${node.cellPosition}');
  }

  void _onSelectingColumnChanged() {
    if (!_enableTableDebugLog) {
      return;
    }

    Log.debug('selectingColumn: ${selectingColumn.value}');
  }

  void _onSelectingRowChanged() {
    if (!_enableTableDebugLog) {
      return;
    }

    Log.debug('selectingRow: ${selectingRow.value}');
  }

  void _onSelectingTableChanged() {
    if (!_enableTableDebugLog) {
      return;
    }

    Log.debug('isSelectingTable: ${isSelectingTable.value}');
  }

  void _onHoveringOnTableBlockChanged() {
    if (!_enableTableDebugLog) {
      return;
    }

    Log.debug('isHoveringOnTableBlock: ${isHoveringOnTableBlock.value}');
  }

  void _onHoveringOnTableAreaChanged() {
    if (!_enableTableDebugLog) {
      return;
    }

    Log.debug('isHoveringOnTableArea: ${isHoveringOnTableArea.value}');
  }

  void _onDraggingColumnChanged() {
    if (!_enableTableDebugLog) {
      return;
    }

    Log.debug('isDraggingColumn: ${isReorderingColumn.value}');
  }

  void _onDraggingRowChanged() {
    if (!_enableTableDebugLog) {
      return;
    }

    Log.debug('isDraggingRow: ${isReorderingRow.value}');
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
    isReorderingColumn.dispose();
    isReorderingRow.dispose();
    reorderingOffset.dispose();
    isEditingCell.dispose();
    isReorderingHitIndex.dispose();
  }
}

class SimpleTableConstants {
  /// Table
  static const defaultColumnWidth = 120.0;
  static const minimumColumnWidth = 36.0;

  static const defaultRowHeight = 36.0;

  static double get tableHitTestTopPadding =>
      UniversalPlatform.isDesktop ? 8.0 : 24.0;
  static double get tableHitTestLeftPadding =>
      UniversalPlatform.isDesktop ? 0.0 : 24.0;
  static double get tableLeftPadding => UniversalPlatform.isDesktop ? 8.0 : 0.0;

  static const tableBottomPadding =
      addRowButtonHeight + 3 * addRowButtonPadding;
  static const tableRightPadding =
      addColumnButtonWidth + 2 * SimpleTableConstants.addColumnButtonPadding;

  static EdgeInsets get tablePadding => EdgeInsets.only(
        // don't add padding to the top of the table, the first row will have padding
        //  to make the column action button clickable.
        bottom: tableBottomPadding,
        left: tableLeftPadding,
        right: tableRightPadding,
      );

  static double get tablePageOffset => UniversalPlatform.isMobile
      ? EditorStyleCustomizer.optionMenuWidth +
          EditorStyleCustomizer.nodeHorizontalPadding * 2
      : EditorStyleCustomizer.optionMenuWidth + 12;

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

  /// Only displaying the add row / add column / add column and row button
  ///   when hovering on the last row / last column / last cell.
  static const enableHoveringLogicV2 = true;

  /// Enable the drag to expand the table
  static const enableDragToExpandTable = false;

  /// Action sheet hit test area on Mobile
  static const rowActionSheetHitTestAreaWidth = 24.0;
  static const columnActionSheetHitTestAreaHeight = 24.0;

  static const actionSheetQuickActionSectionHeight = 44.0;
  static const actionSheetInsertSectionHeight = 52.0;
  static const actionSheetContentSectionHeight = 44.0;
  static const actionSheetNormalActionSectionHeight = 48.0;
  static const actionSheetButtonRadius = 12.0;

  static const actionSheetBottomSheetHeight = 320.0;
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

  Color get simpleTableActionButtonBackgroundColor => Theme.of(this).isLightMode
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF2D3036);

  Color get simpleTableInsertActionBackgroundColor => Theme.of(this).isLightMode
      ? const Color(0xFFF2F2F7)
      : const Color(0xFF2D3036);
}
