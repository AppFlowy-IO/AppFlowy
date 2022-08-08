import 'dart:math';

import 'package:flowy_editor/document/node.dart';
import 'package:flowy_editor/editor_state.dart';
import 'package:flowy_editor/infra/flowy_svg.dart';
import 'package:flowy_editor/operation/transaction_builder.dart';
import 'package:flowy_editor/render/rich_text/rich_text_style.dart';
import 'package:flowy_editor/service/default_text_operations/format_rich_text_style.dart';
import 'package:flowy_editor/service/keyboard_service.dart';
import 'package:flowy_editor/extensions/node_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final List<PopupListItem> _popupListItems = [
  PopupListItem(
    text: 'Text',
    icon: _popupListIcon('text'),
    handler: (editorState) => formatText(editorState),
  ),
  PopupListItem(
    text: 'Heading 1',
    icon: _popupListIcon('h1'),
    handler: (editorState) => formatHeading(editorState, StyleKey.h1),
  ),
  PopupListItem(
    text: 'Heading 2',
    icon: _popupListIcon('h2'),
    handler: (editorState) => formatHeading(editorState, StyleKey.h2),
  ),
  PopupListItem(
    text: 'Heading 3',
    icon: _popupListIcon('h3'),
    handler: (editorState) => formatHeading(editorState, StyleKey.h3),
  ),
  PopupListItem(
    text: 'Bullets',
    icon: _popupListIcon('bullets'),
    handler: (editorState) => formatBulletedList(editorState),
  ),
  PopupListItem(
    text: 'Numbered list',
    icon: _popupListIcon('number'),
    handler: (editorState) => debugPrint('Not implement yet!'),
  ),
  PopupListItem(
    text: 'Checkboxes',
    icon: _popupListIcon('checkbox'),
    handler: (editorState) => formatCheckbox(editorState),
  ),
];

OverlayEntry? _popupListOverlay;
EditorState? _editorState;
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

  final rect = selectable.getCursorRectInPosition(selection.start);
  if (rect == null) {
    return KeyEventResult.ignored;
  }
  final offset = selectable.localToGlobal(rect.topLeft);
  if (!selection.isCollapsed) {
    TransactionBuilder(editorState)
      ..deleteText(
        textNode,
        selection.start.offset,
        selection.end.offset - selection.start.offset,
      )
      ..commit();
  }

  _popupListOverlay?.remove();
  _popupListOverlay = OverlayEntry(
    builder: (context) => Positioned(
      top: offset.dy + 15.0,
      left: offset.dx + 5.0,
      child: PopupListWidget(
        editorState: editorState,
        items: _popupListItems,
      ),
    ),
  );

  Overlay.of(context)?.insert(_popupListOverlay!);

  editorState.service.selectionService.currentSelection
      .removeListener(clearPopupListOverlay);
  editorState.service.selectionService.currentSelection
      .addListener(clearPopupListOverlay);
  // editorState.service.keyboardService?.disable();
  _editorState = editorState;

  return KeyEventResult.handled;
};

void clearPopupListOverlay() {
  _popupListOverlay?.remove();
  _popupListOverlay = null;

  _editorState?.service.keyboardService?.enable();
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
  final focusNode = FocusNode(debugLabel: 'popup_list_widget');
  var selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    focusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: focusNode,
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildColumns(widget.items, selectedIndex),
        ),
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
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (0 <= selectedIndex && selectedIndex < widget.items.length) {
        widget.items[selectedIndex].handler(widget.editorState);
        return KeyEventResult.handled;
      }
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      clearPopupListOverlay();
      return KeyEventResult.handled;
    }

    var newSelectedIndex = selectedIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      newSelectedIndex -= widget.maxItemInRow;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      newSelectedIndex += widget.maxItemInRow;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      newSelectedIndex -= 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      newSelectedIndex += 1;
    }
    if (newSelectedIndex != selectedIndex) {
      setState(() {
        selectedIndex = max(0, min(widget.items.length - 1, newSelectedIndex));
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
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
    this.message = '',
    required this.icon,
    required this.handler,
  });

  final String text;
  final String message;
  final Widget icon;
  final void Function(EditorState editorState) handler;
}

Widget _popupListIcon(String name) => FlowySvg(
      name: 'popup_list/$name',
      color: Colors.black,
      size: const Size.square(18.0),
    );
