import 'dart:math';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef SelectionMenuListItemHandler = void Function(
  EditorState editorState,
  SelectionMenuListService menuService,
  BuildContext context,
);

/// Selection Menu Item
class SelectionMenuListItem {
  SelectionMenuListItem({
    required this.name,
    required this.group,
    required this.icon,
    required this.subtitle,
    required this.tooltipIcon,
    required this.keywords,
    required SelectionMenuListItemHandler handler,
  }) {
    this.handler = (editorState, menuService, context) {
      _deleteSlash(editorState);
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        handler(editorState, menuService, context);
      });
    };
  }

  final String name;
  final String subtitle;
  final Widget Function(EditorState editorState, bool onSelected) tooltipIcon;

  final SelectionMenuListGroup group;

  final Widget Function(EditorState editorState, bool onSelected) icon;

  /// Customizes keywords for item.
  ///
  /// The keywords are used to quickly retrieve items.
  final List<String> keywords;
  late final SelectionMenuListItemHandler handler;

  void _deleteSlash(EditorState editorState) {
    final selectionService = editorState.service.selectionService;
    final selection = selectionService.currentSelection.value;
    final nodes = selectionService.currentSelectedNodes;
    if (selection != null && nodes.length == 1) {
      final node = nodes.first as TextNode;
      final end = selection.start.offset;
      final lastSlashIndex =
          node.toPlainText().substring(0, end).lastIndexOf('/');
      // delete all the texts after '/' along with '/'
      final transaction = editorState.transaction
        ..deleteText(
          node,
          lastSlashIndex,
          end - lastSlashIndex,
        );

      editorState.apply(transaction);
    }
  }

  /// Creates a selection menu entry for inserting a [Node].
  /// [name] and [iconData] define the appearance within the selection menu.
  ///
  /// The insert position is determined by the result of [replace] and
  /// [insertBefore]
  /// If no values are provided for [replace] and [insertBefore] the node is
  /// inserted after the current selection.
  /// [replace] takes precedence over [insertBefore]
  ///
  /// [updateSelection] can be used to update the selection after the node
  /// has been inserted.
  factory SelectionMenuListItem.node({
    required String name,
    required String subtitle,
    required SelectionMenuListGroup group,
    required IconData iconData,
    required IconData tooltipIconData,
    required List<String> keywords,
    required Node Function(EditorState editorState) nodeBuilder,
    bool Function(EditorState editorState, TextNode textNode)? insertBefore,
    bool Function(EditorState editorState, TextNode textNode)? replace,
    Selection? Function(
      EditorState editorState,
      Path insertPath,
      bool replaced,
      bool insertedBefore,
    )?
        updateSelection,
  }) {
    return SelectionMenuListItem(
      name: name,
      subtitle: subtitle,
      group: group,
      tooltipIcon: (editorState, onSelected) => Icon(
        tooltipIconData,
        color: onSelected
            ? editorState.editorStyle.selectionMenuItemSelectedIconColor
            : editorState.editorStyle.selectionMenuItemIconColor,
        size: 18.0,
      ),
      icon: (editorState, onSelected) => Icon(
        iconData,
        color: onSelected
            ? editorState.editorStyle.selectionMenuItemSelectedIconColor
            : editorState.editorStyle.selectionMenuItemIconColor,
        size: 18.0,
      ),
      keywords: keywords,
      handler: (editorState, _, __) {
        final selection =
            editorState.service.selectionService.currentSelection.value;
        final textNodes = editorState
            .service.selectionService.currentSelectedNodes
            .whereType<TextNode>();
        if (textNodes.length != 1 || selection == null) {
          return;
        }
        final textNode = textNodes.first;
        final node = nodeBuilder(editorState);
        final transaction = editorState.transaction;
        final bReplace = replace?.call(editorState, textNode) ?? false;
        final bInsertBefore =
            insertBefore?.call(editorState, textNode) ?? false;

        //default insert after
        var path = textNode.path.next;
        if (bReplace) {
          path = textNode.path;
        } else if (bInsertBefore) {
          path = textNode.path;
        }

        transaction
          ..insertNode(path, node)
          ..afterSelection = updateSelection?.call(
                  editorState, path, bReplace, bInsertBefore) ??
              selection;

        if (bReplace) {
          transaction.deleteNode(textNode);
        }

        editorState.apply(transaction);
      },
    );
  }
}

class SelectionMenuListWidget extends StatefulWidget {
  const SelectionMenuListWidget({
    Key? key,
    required this.items,
    required this.maxItemInRow,
    required this.editorState,
    required this.menuService,
    required this.onExit,
    required this.onSelectionUpdate,
  }) : super(key: key);

  final List<SelectionMenuListItem> items;
  final int maxItemInRow;

  final SelectionMenuListService menuService;
  final EditorState editorState;

  final VoidCallback onSelectionUpdate;
  final VoidCallback onExit;

  @override
  State<SelectionMenuListWidget> createState() =>
      _SelectionMenuListWidgetState();
}

class _SelectionMenuListWidgetState extends State<SelectionMenuListWidget> {
  final _focusNode =
      FocusNode(debugLabel: 'popup_list_widget', skipTraversal: true);

  int _selectedIndex = 0;
  int travelled = 0;

  int hoveringIndex = 0;
  bool hovering = false;
  List<SelectionMenuListItem> _showingItems = [];
  ScrollController listViewScrollConroller = ScrollController(
    keepScrollOffset: true,
  );
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
            final value = keyword.contains(newKeyword.toLowerCase());
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

  _onHover(
    value,
    index,
  ) {
    setState(() {
      hovering = value;
      hoveringIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
        focusNode: _focusNode,
        onKey: _onKey,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color:
                    widget.editorState.editorStyle.selectionMenuBackgroundColor,
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
                      (v, i, r) {
                        _onHover(
                          v,
                          i,
                        );
                      },
                    ),
            ),
            _buildTooltip()
          ],
        ));
  }

  _buildTooltip() {
    return !hovering
        ? Container()
        : Positioned(
            right: -160,
            height: 158,
            width: 150,
            child: Container(
              width: 170,
              height: 180,
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.all(
                  Radius.circular(6),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 100,
                    width: 150,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                    child: _showingItems[hoveringIndex]
                        .icon(widget.editorState, false),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Material(
                    color: Colors.transparent,
                    child: Text(
                      _showingItems[hoveringIndex].subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }

  Widget _buildGroupTag(
    BuildContext context,
    String text,
  ) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 1,
              width: 300.0,
              color: Colors.grey.shade300,
              alignment: Alignment.center,
            ),
            const SizedBox(
              height: 5,
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsWidget(
    BuildContext buildContext,
    List<SelectionMenuListItem> items,
    int selectedIndex,
    void Function(bool value, int index, double position) onHover,
  ) {
    List<Widget> columns = [];
    List<Widget> itemWidgets = [];

    List<String> groups = [];
    for (int k = 0; k < SelectionMenuListGroup.values.length; k++) {
      if (items.firstWhereOrNull(
              (element) => element.group == SelectionMenuListGroup.values[k]) !=
          null) {
        groups.add(SelectionMenuListGroup.values[k].name);
      }
    }

    for (int j = 0; j < groups.length; j++) {
      itemWidgets.add(_buildGroupTag(context, groups[j]));
      for (var i = 0; i < items.length; i++) {
        if (groups[j] == items[i].group.name) {
          itemWidgets.add(
            SelectionMenuListItemWidget(
              index: i,
              item: items[i],
              isSelected: selectedIndex == i,
              editorState: widget.editorState,
              menuService: widget.menuService,
              hovering: (value) {
                _onHover(value, i);
              },
            ),
          );
        }
      }
    }

    if (itemWidgets.isNotEmpty) {
      columns.add(Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: itemWidgets,
      ));
      itemWidgets = [];
    }
    return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 0, maxHeight: 300),
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          controller: listViewScrollConroller,
          child: Column(
            children: columns,
          ),
        ));
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

  scrollIfNeeded(int index, double itemHeight) {
    double itemTop = index * itemHeight;
    double itemBottom = itemTop + itemHeight;
    double viewportHeight = listViewScrollConroller.position.viewportDimension;
    double visibleTop = listViewScrollConroller.position.pixels;
    double visibleBottom = visibleTop + viewportHeight;

    if (itemTop < visibleTop) {
      listViewScrollConroller.animateTo(
        itemTop,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
      );
    } else if (itemBottom > visibleBottom) {
      listViewScrollConroller.animateTo(
        itemBottom - viewportHeight,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
      );
    }
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
        _showingItems[_selectedIndex]
            .handler(widget.editorState, widget.menuService, context);
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
        !arrowKeys.contains(event.logicalKey) &&
        event.logicalKey != LogicalKeyboardKey.tab) {
      keyword += event.character!;
      _insertText(event.character!);
      return KeyEventResult.handled;
    }

    var newSelectedIndex = _selectedIndex;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      newSelectedIndex -= 1;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      newSelectedIndex += 1;
    }

    if (newSelectedIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = newSelectedIndex.clamp(0, _showingItems.length - 1);
      });
      scrollIfNeeded(_selectedIndex, 75.0);

      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  visibility(totalCount, currentIndex) {}

  void _deleteLastCharacters({int length = 1}) {
    final selectionService = widget.editorState.service.selectionService;
    final selection = selectionService.currentSelection.value;
    final nodes = selectionService.currentSelectedNodes;
    if (selection != null && nodes.length == 1) {
      widget.onSelectionUpdate();
      final transaction = widget.editorState.transaction
        ..deleteText(
          nodes.first as TextNode,
          selection.start.offset - length,
          length,
        );
      widget.editorState.apply(transaction);
    }
  }

  void _insertText(String text) {
    final selection =
        widget.editorState.service.selectionService.currentSelection.value;
    final nodes =
        widget.editorState.service.selectionService.currentSelectedNodes;
    if (selection != null && nodes.length == 1) {
      widget.onSelectionUpdate();
      final transaction = widget.editorState.transaction
        ..insertText(
          nodes.first as TextNode,
          selection.end.offset,
          text,
        );
      widget.editorState.apply(
        transaction,
      );
    }
  }
}
