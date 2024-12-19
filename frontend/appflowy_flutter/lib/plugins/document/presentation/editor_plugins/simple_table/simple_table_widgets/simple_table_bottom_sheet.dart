import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_color_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_widgets/_simple_table_bottom_sheet_actions.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';

enum _SimpleTableBottomSheetMenuState {
  actionMenu,
  textColor,
  textBackgroundColor,
}

// Note: This widget is only used for mobile.
class SimpleTableBottomSheet extends StatefulWidget {
  const SimpleTableBottomSheet({
    super.key,
    required this.type,
    required this.cellNode,
    required this.editorState,
  });

  final SimpleTableMoreActionType type;
  final Node cellNode;
  final EditorState editorState;

  @override
  State<SimpleTableBottomSheet> createState() => _SimpleTableBottomSheetState();
}

class _SimpleTableBottomSheetState extends State<SimpleTableBottomSheet> {
  _SimpleTableBottomSheetMenuState menuState =
      _SimpleTableBottomSheetMenuState.actionMenu;

  Color? selectedTextColor;
  Color? selectedTextBackgroundColor;

  @override
  void initState() {
    super.initState();

    selectedTextColor = widget.cellNode.textColorInColumn?.tryToColor();
    selectedTextBackgroundColor = widget.cellNode.textColorInRow?.tryToColor();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header
        _buildHeader(),

        // content
        ..._buildContent(),
      ],
    );
  }

  Widget _buildHeader() {
    switch (menuState) {
      case _SimpleTableBottomSheetMenuState.actionMenu:
        return BottomSheetHeader(
          showBackButton: false,
          showCloseButton: true,
          showDoneButton: false,
          showRemoveButton: false,
          title: widget.type.name.capitalize(),
          onClose: () => Navigator.pop(context),
        );
      case _SimpleTableBottomSheetMenuState.textColor ||
            _SimpleTableBottomSheetMenuState.textBackgroundColor:
        return BottomSheetHeader(
          showBackButton: false,
          showCloseButton: true,
          showDoneButton: false,
          showRemoveButton: false,
          title: widget.type.name.capitalize(),
          onClose: () => setState(() {
            menuState = _SimpleTableBottomSheetMenuState.actionMenu;
          }),
        );
    }
  }

  List<Widget> _buildContent() {
    switch (menuState) {
      case _SimpleTableBottomSheetMenuState.actionMenu:
        return _buildActionButtons();
      case _SimpleTableBottomSheetMenuState.textColor:
        return _buildTextColor();
      case _SimpleTableBottomSheetMenuState.textBackgroundColor:
        return _buildTextBackgroundColor();
    }
  }

  List<Widget> _buildActionButtons() {
    return [
      // copy, cut, paste, delete
      SimpleTableQuickActions(
        type: widget.type,
        cellNode: widget.cellNode,
        editorState: widget.editorState,
      ),
      const VSpace(12),

      // insert row, insert column
      SimpleTableInsertActions(
        type: widget.type,
        cellNode: widget.cellNode,
        editorState: widget.editorState,
      ),
      const VSpace(12),

      // content actions
      SimpleTableContentActions(
        type: widget.type,
        cellNode: widget.cellNode,
        editorState: widget.editorState,
        onTextColorSelected: () {
          setState(() {
            menuState = _SimpleTableBottomSheetMenuState.textColor;
          });
        },
        onTextBackgroundColorSelected: () {
          setState(() {
            menuState = _SimpleTableBottomSheetMenuState.textBackgroundColor;
          });
        },
      ),
      const VSpace(16),

      // action buttons
      SimpleTableActionButtons(
        type: widget.type,
        cellNode: widget.cellNode,
        editorState: widget.editorState,
      ),
    ];
  }

  List<Widget> _buildTextColor() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
        ),
        child: FlowyText(
          LocaleKeys.document_plugins_simpleTable_moreActions_textColor.tr(),
          fontSize: 14.0,
        ),
      ),
      const VSpace(12.0),
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: EditorTextColorWidget(
          onSelectedColor: _onTextColorSelected,
          selectedColor: selectedTextColor,
        ),
      ),
    ];
  }

  List<Widget> _buildTextBackgroundColor() {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
        ),
        child: FlowyText(
          LocaleKeys
              .document_plugins_simpleTable_moreActions_cellBackgroundColor
              .tr(),
          fontSize: 14.0,
        ),
      ),
      const VSpace(12.0),
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: EditorBackgroundColors(
          onSelectedColor: _onTextBackgroundColorSelected,
          selectedColor: selectedTextBackgroundColor,
        ),
      ),
    ];
  }

  void _onTextColorSelected(Color color) {
    final hex = color.alpha == 0 ? null : color.toHex();
    switch (widget.type) {
      case SimpleTableMoreActionType.column:
        widget.editorState.updateColumnTextColor(
          tableCellNode: widget.cellNode,
          color: hex ?? '',
        );
      case SimpleTableMoreActionType.row:
        widget.editorState.updateRowTextColor(
          tableCellNode: widget.cellNode,
          color: hex ?? '',
        );
    }

    setState(() {
      selectedTextColor = color;
    });
  }

  void _onTextBackgroundColorSelected(Color color) {
    final hex = color.alpha == 0 ? null : color.toHex();
    switch (widget.type) {
      case SimpleTableMoreActionType.column:
        widget.editorState.updateColumnBackgroundColor(
          tableCellNode: widget.cellNode,
          color: hex ?? '',
        );
      case SimpleTableMoreActionType.row:
        widget.editorState.updateRowBackgroundColor(
          tableCellNode: widget.cellNode,
          color: hex ?? '',
        );
    }

    setState(() {
      selectedTextBackgroundColor = color;
    });
  }
}
