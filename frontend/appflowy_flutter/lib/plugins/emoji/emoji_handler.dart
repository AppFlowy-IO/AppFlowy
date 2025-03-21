import 'dart:async';
import 'dart:math';

import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'emoji_menu.dart';

class EmojiHandler extends StatefulWidget {
  const EmojiHandler({
    super.key,
    required this.editorState,
    required this.menuService,
    required this.onDismiss,
    required this.onSelectionUpdate,
    required this.onEmojiSelect,
    this.startCharAmount = 1,
    this.cancelBySpaceHandler,
  });

  final EditorState editorState;
  final EmojiMenuService menuService;
  final VoidCallback onDismiss;
  final VoidCallback onSelectionUpdate;
  final SelectEmojiItemHandler onEmojiSelect;
  final int startCharAmount;
  final bool Function()? cancelBySpaceHandler;

  @override
  State<EmojiHandler> createState() => _EmojiHandlerState();
}

class _EmojiHandlerState extends State<EmojiHandler> {
  final _focusNode = FocusNode(debugLabel: 'emoji_menu_handler');
  final ItemScrollController controller = ItemScrollController();
  late EmojiData emojiData;
  final List<Emoji> searchedEmojis = [];
  bool loaded = false;
  int invalidCounter = 0;
  late int startOffset;
  String _search = '';

  set search(String search) {
    _search = search;
    _doSearch();
  }

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );

    startOffset = widget.editorState.selection?.endIndex ?? 0;

    if (kCachedEmojiData != null) {
      loadEmojis(kCachedEmojiData!);
    } else {
      EmojiData.builtIn().then(
        (value) {
          kCachedEmojiData = value;
          loadEmojis(value);
        },
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noEmojis = searchedEmojis.isEmpty;
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: onKeyEvent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400, maxWidth: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6.0),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              spreadRadius: 1,
              color: Colors.black.withAlpha(25),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: noEmojis
              ? CircularProgressIndicator()
              : Flexible(
                  child: ScrollablePositionedList.builder(
                    itemCount: searchedEmojis.length,
                    itemScrollController: controller,
                    shrinkWrap: true,
                    physics: const ClampingScrollPhysics(),
                    itemBuilder: (ctx, index) {
                      final selectedEmoji = searchedEmojis[index];
                      final displayedEmoji =
                          emojiData.getEmojiById(selectedEmoji.id);
                      final isSelected = _selectedIndex == index;
                      return SizedBox(
                        height: 32,
                        child: FlowyButton(
                          text: FlowyText.medium(
                            '$displayedEmoji ${selectedEmoji.name}',
                            lineHeight: 1.0,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isSelected: isSelected,
                          onTap: () => onSelect(index),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  void loadEmojis(EmojiData data) {
    emojiData = data;
    searchedEmojis.clear();
    searchedEmojis.addAll(emojiData.emojis.values);
    if (mounted) {
      setState(() {
        loaded = true;
      });
    }
  }

  Future<void> _doSearch() async {
    if (!loaded) return;
    final searchEmojiData = emojiData.filterByKeyword(_search);
    setState(() {
      searchedEmojis.clear();
      searchedEmojis.addAll(searchEmojiData.emojis.values);
      _selectedIndex = 0;
    });
    if (searchedEmojis.isEmpty) {
      widget.onDismiss.call();
    }
  }

  KeyEventResult onKeyEvent(focus, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    const moveKeys = [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
    ];

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      onSelect(_selectedIndex);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      // Workaround to bring focus back to editor
      widget.editorState
          .updateSelectionWithReason(widget.editorState.selection);
      widget.onDismiss.call();
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_search.isEmpty) {
        if (_canDeleteLastCharacter()) {
          widget.editorState.deleteBackward();
        } else {
          // Workaround for editor regaining focus
          widget.editorState.apply(
            widget.editorState.transaction
              ..afterSelection = widget.editorState.selection,
          );
        }
        widget.onDismiss.call();
      } else {
        widget.onSelectionUpdate();
        widget.editorState.deleteBackward();
        _deleteCharacterAtSelection();
      }

      return KeyEventResult.handled;
    } else if (event.character != null &&
        ![
          ...moveKeys,
          LogicalKeyboardKey.arrowLeft,
          LogicalKeyboardKey.arrowRight,
        ].contains(event.logicalKey)) {
      /// Prevents dismissal of context menu by notifying the parent
      /// that the selection change occurred from the handler.
      widget.onSelectionUpdate();

      if (event.logicalKey == LogicalKeyboardKey.space) {
        final cancelBySpaceHandler = widget.cancelBySpaceHandler;
        if (cancelBySpaceHandler != null && cancelBySpaceHandler()) {
          return KeyEventResult.handled;
        }
      }

      // Interpolation to avoid having a getter for private variable
      _insertCharacter(event.character!);
      return KeyEventResult.handled;
    } else if (moveKeys.contains(event.logicalKey)) {
      _moveSelection(event.logicalKey);
      return KeyEventResult.handled;
    }

    if ([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight]
        .contains(event.logicalKey)) {
      widget.onSelectionUpdate();

      event.logicalKey == LogicalKeyboardKey.arrowLeft
          ? widget.editorState.moveCursorForward()
          : widget.editorState.moveCursorBackward(SelectionMoveRange.character);

      /// If cursor moves before @ then dismiss menu
      /// If cursor moves after @search.length then dismiss menu
      final selection = widget.editorState.selection;
      if (selection != null &&
          (selection.endIndex < startOffset ||
              selection.endIndex > (startOffset + _search.length))) {
        widget.onDismiss.call();
      }

      /// Workaround: When using the move cursor methods, it seems the
      ///  focus goes back to the editor, this makes sure this handler
      ///  receives the next keypress.
      ///
      _focusNode.requestFocus();

      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
  }

  void onSelect(int index) {
    widget.onEmojiSelect.call(
      context,
      (
        startOffset - widget.startCharAmount,
        _search.length + widget.startCharAmount
      ),
      emojiData.getEmojiById(searchedEmojis[index].id),
    );
    widget.onDismiss.call();
  }

  void _insertCharacter(String character) {
    widget.editorState.insertTextAtCurrentSelection(character);

    final selection = widget.editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final delta = widget.editorState.getNodeAtPath(selection.end.path)?.delta;
    if (delta == null) {
      return;
    }

    search = widget.editorState
        .getTextInSelection(
          selection.copyWith(
            start: selection.start.copyWith(offset: startOffset),
            end: selection.start
                .copyWith(offset: startOffset + _search.length + 1),
          ),
        )
        .join();
  }

  void _moveSelection(LogicalKeyboardKey key) {
    bool didChange = false;

    if (key == LogicalKeyboardKey.arrowUp ||
        (key == LogicalKeyboardKey.tab &&
            HardwareKeyboard.instance.isShiftPressed)) {
      if (_selectedIndex == 0) {
        _selectedIndex = max(0, searchedEmojis.length - 1);
        didChange = true;
      } else if (_selectedIndex > 0) {
        _selectedIndex -= 1;
        didChange = true;
      }
    } else if ([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.tab]
        .contains(key)) {
      if (_selectedIndex < searchedEmojis.length - 1) {
        _selectedIndex += 1;
        didChange = true;
      } else if (_selectedIndex == searchedEmojis.length - 1) {
        _selectedIndex = 0;
        didChange = true;
      }
    }

    if (mounted && didChange) {
      setState(() {});
      _scrollToItem();
    }
  }

  void _scrollToItem() {
    controller.scrollTo(
      index: _selectedIndex,
      duration: const Duration(milliseconds: 200),
      alignment: 0.5,
    );
  }

  void _deleteCharacterAtSelection() {
    final selection = widget.editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final node = widget.editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }

    search = delta.toPlainText().substring(
          startOffset,
          startOffset - 1 + _search.length,
        );
  }

  bool _canDeleteLastCharacter() {
    final selection = widget.editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return false;
    }

    final delta = widget.editorState.getNodeAtPath(selection.start.path)?.delta;
    if (delta == null) {
      return false;
    }

    return delta.isNotEmpty;
  }
}

typedef SelectEmojiItemHandler = void Function(
  BuildContext context,
  (int start, int end) replacement,
  String emoji,
);
