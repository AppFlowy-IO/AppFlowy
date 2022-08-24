import 'dart:math';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_item_widget.dart';
import 'package:appflowy_editor/src/render/selection_menu/selection_menu_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Selection Menu Item
class SelectionMenuItem {
  SelectionMenuItem({
    required this.name,
    required this.icon,
    required this.keywords,
    required this.handler,
  });

  final String name;
  final Widget icon;

  /// Customizes keywords for item.
  ///
  /// The keywords are used to quickly retrieve items.
  final List<String> keywords;
  final void Function(
    EditorState editorState,
    SelectionMenuService menuService,
    BuildContext context,
  ) handler;
}

class SelectionMenuWidget extends StatefulWidget {
  const SelectionMenuWidget({
    Key? key,
    required this.items,
    required this.maxItemInRow,
    required this.editorState,
    required this.menuService,
    required this.onExit,
    required this.onSelectionUpdate,
  }) : super(key: key);

  final List<SelectionMenuItem> items;
  final int maxItemInRow;

  final SelectionMenuService menuService;
  final EditorState editorState;

  final VoidCallback onSelectionUpdate;
  final VoidCallback onExit;

  @override
  State<SelectionMenuWidget> createState() => _SelectionMenuWidgetState();
}

class _SelectionMenuWidgetState extends State<SelectionMenuWidget> {
  final _focusNode = FocusNode(debugLabel: 'popup_list_widget');

  int _selectedIndex = 0;
  List<SelectionMenuItem> _showingItems = [];

  String _keyword = '';
  String get keyword => _keyword;
  set keyword(String newKeyword) {
    _keyword = newKeyword;

    // Search items according to the keyword, and calculate the length of
    //  the longest keyword, which is used to dismiss the selection_service.
    var maxKeywordLength = 0;
    final items = widget.items
        .where(
          (item) => item.keywords.any((keyword) {
            final value = keyword.contains(newKeyword);
            if (value) {
              maxKeywordLength = max(maxKeywordLength, keyword.length);
            }
            return value;
          }),
        )
        .toList(growable: false);

    Log.ui.debug('$items');

    if (keyword.length >= maxKeywordLength + 2) {
      widget.onExit();
    } else {
      setState(() {
        _showingItems = items;
      });
    }
  }

  @override
  void initState() {
    super.initState();

    _showingItems = widget.items;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: _onKey,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: _showingItems.isEmpty
            ? _buildNoResultsWidget(context)
            : _buildResultsWidget(
                context,
                _showingItems,
                _selectedIndex,
              ),
      ),
    );
  }

  Widget _buildResultsWidget(
    BuildContext buildContext,
    List<SelectionMenuItem> items,
    int selectedIndex,
  ) {
    List<Widget> columns = [];
    List<Widget> itemWidgets = [];
    for (var i = 0; i < items.length; i++) {
      if (i != 0 && i % (widget.maxItemInRow) == 0) {
        columns.add(Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: itemWidgets,
        ));
        itemWidgets = [];
      }
      itemWidgets.add(SelectionMenuItemWidget(
        item: items[i],
        isSelected: selectedIndex == i,
        editorState: widget.editorState,
        menuService: widget.menuService,
      ));
    }
    if (itemWidgets.isNotEmpty) {
      columns.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: itemWidgets,
      ));
      itemWidgets = [];
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  Widget _buildNoResultsWidget(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Material(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Text(
            'No results',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  /// Handles arrow keys to switch selected items
  /// Handles keyword searches
  /// Handles enter to select item and esc to exit
  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    Log.keyboard.debug('slash command, on key $event');
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final arrowKeys = [
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown
    ];

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (0 <= _selectedIndex && _selectedIndex < _showingItems.length) {
        _deleteLastCharacters(length: keyword.length + 1);
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          _showingItems[_selectedIndex]
              .handler(widget.editorState, widget.menuService, context);
        });
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onExit();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (keyword.isEmpty) {
        widget.onExit();
      } else {
        keyword = keyword.substring(0, keyword.length - 1);
      }
      _deleteLastCharacters();
      return KeyEventResult.handled;
    } else if (event.character != null &&
        !arrowKeys.contains(event.logicalKey)) {
      keyword += event.character!;
      _insertText(event.character!);
      return KeyEventResult.handled;
    }

    var newSelectedIndex = _selectedIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      newSelectedIndex -= widget.maxItemInRow;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      newSelectedIndex += widget.maxItemInRow;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      newSelectedIndex -= 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      newSelectedIndex += 1;
    }
    if (newSelectedIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newSelectedIndex.clamp(0, _showingItems.length - 1);
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _deleteLastCharacters({int length = 1}) {
    final selectionService = widget.editorState.service.selectionService;
    final selection = selectionService.currentSelection.value;
    final nodes = selectionService.currentSelectedNodes;
    if (selection != null && nodes.length == 1) {
      widget.onSelectionUpdate();
      TransactionBuilder(widget.editorState)
        ..deleteText(
          nodes.first as TextNode,
          selection.start.offset - length,
          length,
        )
        ..commit();
    }
  }

  void _insertText(String text) {
    final selection =
        widget.editorState.service.selectionService.currentSelection.value;
    final nodes =
        widget.editorState.service.selectionService.currentSelectedNodes;
    if (selection != null && nodes.length == 1) {
      widget.onSelectionUpdate();
      TransactionBuilder(widget.editorState)
        ..insertText(
          nodes.first as TextNode,
          selection.end.offset,
          text,
        )
        ..commit();
    }
  }
}
