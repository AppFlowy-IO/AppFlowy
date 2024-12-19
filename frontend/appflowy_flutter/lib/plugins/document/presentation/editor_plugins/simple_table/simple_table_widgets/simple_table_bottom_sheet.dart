import 'package:appflowy/mobile/presentation/bottom_sheet/show_mobile_bottom_sheet.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/base/string_extension.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/mobile_toolbar_v3/aa_menu/_color_list.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/simple_table/simple_table_widgets/_simple_table_bottom_sheet_actions.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
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
      const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
        ),
        child: FlowyText(
          // TODO: i18n
          'Text',
          fontSize: 14.0,
        ),
      ),
      const VSpace(12.0),
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: EditorTextColorWidget(onSelectedColor: (_) {}),
      ),
    ];
  }

  List<Widget> _buildTextBackgroundColor() {
    return [
      const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 16.0,
        ),
        child: FlowyText(
          // TODO: i18n
          'Cell background',
          fontSize: 14.0,
        ),
      ),
      const VSpace(12.0),
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 8.0,
        ),
        child: EditorBackgroundColors(onSelectedColor: (_) {}),
      ),
    ];
  }
}
