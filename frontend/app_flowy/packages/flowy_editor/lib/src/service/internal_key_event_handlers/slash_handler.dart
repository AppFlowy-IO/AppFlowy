import 'dart:math';

import 'package:flowy_editor/src/document/node.dart';
import 'package:flowy_editor/src/editor_state.dart';
import 'package:flowy_editor/src/infra/flowy_svg.dart';
import 'package:flowy_editor/src/operation/transaction_builder.dart';
import 'package:flowy_editor/src/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/src/service/default_text_operations/format_rich_text_style.dart';
import 'package:flowy_editor/src/service/keyboard_service.dart';
import 'package:flowy_editor/src/extensions/node_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final List<PopupListItem> _popupListItems = [
  PopupListItem(
    text: 'Text',
    keywords: ['text'],
    icon: _popupListIcon('text'),
    handler: (editorState) {
      insertTextNodeAfterSelection(editorState, {});
    },
  ),
  PopupListItem(
    text: 'Heading 1',
    keywords: ['h1', 'heading 1'],
    icon: _popupListIcon('h1'),
    handler: (editorState) =>
        insertHeadingAfterSelection(editorState, StyleKey.h1),
  ),
  PopupListItem(
    text: 'Heading 2',
    keywords: ['h2', 'heading 2'],
    icon: _popupListIcon('h2'),
    handler: (editorState) =>
        insertHeadingAfterSelection(editorState, StyleKey.h2),
  ),
  PopupListItem(
    text: 'Heading 3',
    keywords: ['h3', 'heading 3'],
    icon: _popupListIcon('h3'),
    handler: (editorState) =>
        insertHeadingAfterSelection(editorState, StyleKey.h3),
  ),
  PopupListItem(
    text: 'Bulleted List',
    keywords: ['bulleted list'],
    icon: _popupListIcon('bullets'),
    handler: (editorState) => insertBulletedListAfterSelection(editorState),
  ),
  // PopupListItem(
  //   text: 'Numbered list',
  //   keywords: ['numbered list'],
  //   icon: _popupListIcon('number'),
  //   handler: (editorState) => debugPrint('Not implement yet!'),
  // ),
  PopupListItem(
    text: 'To-do List',
    keywords: ['checkbox'],
    icon: _popupListIcon('checkbox'),
    handler: (editorState) => insertCheckboxAfterSelection(editorState),
  ),
];

OverlayEntry? _popupListOverlay;
EditorState? _editorState;
bool _selectionChangeBySlash = false;
FlowyKeyEventHandler slashShortcutHandler = (editorState, event) {
  if (event.logicalKey != LogicalKeyboardKey.slash) {
    return KeyEventResult.ignored;
  }

  final textNodes = editorState.service.selectionService.currentSelectedNodes
      .whereType<TextNode>();
  if (textNodes.length != 1) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.service.selectionService.currentSelection.value;
  final textNode = textNodes.first;
  final context = textNode.context;
  final selectable = textNode.selectable;
  if (selection == null || context == null || selectable == null) {
    return KeyEventResult.ignored;
  }
  final selectionRects = editorState.service.selectionService.selectionRects;
  if (selectionRects.isEmpty) {
    return KeyEventResult.ignored;
  }
  TransactionBuilder(editorState)
    ..replaceText(textNode, selection.start.offset,
        selection.end.offset - selection.start.offset, event.character ?? '')
    ..commit();

  _editorState = editorState;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _selectionChangeBySlash = false;
    showPopupList(context, editorState, selectionRects.first.bottomRight);
  });

  return KeyEventResult.handled;
};

void showPopupList(
    BuildContext context, EditorState editorState, Offset offset) {
  _popupListOverlay?.remove();
  _popupListOverlay = OverlayEntry(
    builder: (context) => Positioned(
      top: offset.dy,
      left: offset.dx,
      child: PopupListWidget(
        editorState: editorState,
        items: _popupListItems,
      ),
    ),
  );

  Overlay.of(context)?.insert(_popupListOverlay!);

  editorState.service.selectionService.currentSelection
      .removeListener(clearPopupList);
  editorState.service.selectionService.currentSelection
      .addListener(clearPopupList);

  editorState.service.scrollService?.disable();
}

void clearPopupList() {
  if (_popupListOverlay == null || _editorState == null) {
    return;
  }
  final selection =
      _editorState?.service.selectionService.currentSelection.value;
  if (selection == null) {
    return;
  }
  if (_selectionChangeBySlash) {
    _selectionChangeBySlash = false;
    return;
  }
  _popupListOverlay?.remove();
  _popupListOverlay = null;

  _editorState?.service.keyboardService?.enable();
  _editorState?.service.scrollService?.enable();
  _editorState = null;
}

class PopupListWidget extends StatefulWidget {
  const PopupListWidget({
    Key? key,
    required this.editorState,
    required this.items,
    this.maxItemInRow = 5,
  }) : super(key: key);

  final EditorState editorState;
  final List<PopupListItem> items;
  final int maxItemInRow;

  @override
  State<PopupListWidget> createState() => _PopupListWidgetState();
}

class _PopupListWidgetState extends State<PopupListWidget> {
  final _focusNode = FocusNode(debugLabel: 'popup_list_widget');
  int _selectedIndex = 0;
  List<PopupListItem> _items = [];
  String __keyword = '';
  String get _keyword => __keyword;
  set _keyword(String keyword) {
    __keyword = keyword;
    setState(() {
      _items = widget.items
          .where((item) =>
              item.keywords.any((keyword) => keyword.contains(_keyword)))
          .toList(growable: false);
    });
  }

  @override
  void initState() {
    super.initState();

    _items = widget.items;

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
        child: _items.isEmpty
            ? Align(
                alignment: Alignment.centerLeft,
                child: _buildNoResultsWidget(context),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildColumns(_items, _selectedIndex),
              ),
      ),
    );
  }

  Widget _buildNoResultsWidget(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8.0),
      child: Text(
        'No results',
        style: TextStyle(color: Colors.grey, fontSize: 15.0),
      ),
    );
  }

  List<Widget> _buildColumns(List<PopupListItem> items, int selectedIndex) {
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
      itemWidgets.add(_PopupListItemWidget(
        editorState: widget.editorState,
        item: items[i],
        highlight: selectedIndex == i,
      ));
    }
    if (itemWidgets.isNotEmpty) {
      columns.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: itemWidgets,
      ));
      itemWidgets = [];
    }
    return columns;
  }

  KeyEventResult _onKey(FocusNode node, RawKeyEvent event) {
    debugPrint('slash on key $event');
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
      if (0 <= _selectedIndex && _selectedIndex < _items.length) {
        _deleteLastCharacters(length: _keyword.length + 1);
        _items[_selectedIndex].handler(widget.editorState);
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      clearPopupList();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_keyword.isEmpty) {
        clearPopupList();
      } else {
        _keyword = _keyword.substring(0, _keyword.length - 1);
      }
      _deleteLastCharacters();
      return KeyEventResult.handled;
    } else if (event.character != null &&
        !arrowKeys.contains(event.logicalKey)) {
      _keyword += event.character!;
      _insertText(event.character!);
      var maxKeywordLength = 0;
      for (final item in _items) {
        for (final keyword in item.keywords) {
          maxKeywordLength = max(keyword.length, maxKeywordLength);
        }
      }
      if (_keyword.length >= maxKeywordLength + 2) {
        clearPopupList();
      }
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
        _selectedIndex = max(0, min(_items.length - 1, newSelectedIndex));
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _deleteLastCharacters({int length = 1}) {
    final selection =
        widget.editorState.service.selectionService.currentSelection.value;
    final nodes =
        widget.editorState.service.selectionService.currentSelectedNodes;
    if (selection != null && nodes.length == 1) {
      _selectionChangeBySlash = true;
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
      _selectionChangeBySlash = true;
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

class _PopupListItemWidget extends StatelessWidget {
  const _PopupListItemWidget({
    Key? key,
    required this.highlight,
    required this.item,
    required this.editorState,
  }) : super(key: key);

  final EditorState editorState;
  final PopupListItem item;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8.0, 5.0, 8.0, 5.0),
      child: SizedBox(
        width: 140,
        child: TextButton.icon(
          icon: item.icon,
          style: ButtonStyle(
            alignment: Alignment.centerLeft,
            overlayColor: MaterialStateProperty.all(
              const Color(0xFFE0F8FF),
            ),
            backgroundColor: highlight
                ? MaterialStateProperty.all(const Color(0xFFE0F8FF))
                : MaterialStateProperty.all(Colors.transparent),
          ),
          label: Text(
            item.text,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14.0,
            ),
          ),
          onPressed: () {
            item.handler(editorState);
          },
        ),
      ),
    );
  }
}

class PopupListItem {
  PopupListItem({
    required this.text,
    required this.keywords,
    this.message = '',
    required this.icon,
    required this.handler,
  });

  final String text;
  final List<String> keywords;
  final String message;
  final Widget icon;
  final void Function(EditorState editorState) handler;
}

Widget _popupListIcon(String name) => FlowySvg(
      name: 'popup_list/$name',
      color: Colors.black,
      size: const Size.square(18.0),
    );
