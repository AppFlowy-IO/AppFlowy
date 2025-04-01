import 'dart:async';
import 'dart:math';

import 'package:appflowy/plugins/base/emoji/emoji_picker.dart';
import 'package:appflowy/shared/icon_emoji_picker/emoji_skin_tone.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flowy_infra/size.dart';

import 'package:flowy_infra_ui/style_widget/button.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flowy_infra_ui/widget/flowy_tooltip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_emoji_mart/flutter_emoji_mart.dart';

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
  final focusNode = FocusNode(debugLabel: 'emoji_menu_handler');
  final scrollController = ScrollController();
  late EmojiData emojiData;
  final List<Emoji> searchedEmojis = [];
  bool loaded = false;
  int invalidCounter = 0;
  late int startOffset;
  String _search = '';
  double emojiHeight = 36.0;
  final configuration = EmojiPickerConfiguration(
    defaultSkinTone: lastSelectedEmojiSkinTone ?? EmojiSkinTone.none,
  );

  set search(String search) {
    _search = search;
    _doSearch();
  }

  final ValueNotifier<int> selectedIndexNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => focusNode.requestFocus(),
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
    focusNode.dispose();
    selectedIndexNotifier.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final noEmojis = searchedEmojis.isEmpty;
    return Focus(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 392, maxWidth: 360),
        padding: const EdgeInsets.symmetric(vertical: 16),
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
        child: noEmojis ? buildLoading() : buildEmojis(),
      ),
    );
  }

  Widget buildLoading() {
    return SizedBox(
      width: 400,
      height: 40,
      child: Center(
        child: SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget buildEmojis() {
    return SizedBox(
      height:
          (searchedEmojis.length / configuration.perLine).ceil() * emojiHeight,
      child: GridView.builder(
        controller: scrollController,
        itemCount: searchedEmojis.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: configuration.perLine,
        ),
        itemBuilder: (context, index) {
          final currentEmoji = searchedEmojis[index];
          final emojiId = currentEmoji.id;
          final emoji = emojiData.getEmojiById(
            emojiId,
            skinTone: configuration.defaultSkinTone,
          );
          return ValueListenableBuilder(
            valueListenable: selectedIndexNotifier,
            builder: (context, value, child) {
              final isSelected = value == index;
              return SizedBox.square(
                dimension: emojiHeight,
                child: FlowyButton(
                  isSelected: isSelected,
                  margin: EdgeInsets.zero,
                  radius: Corners.s8Border,
                  text: ManualTooltip(
                    key: ValueKey('$emojiId-$isSelected'),
                    message: currentEmoji.name,
                    showAutomaticlly: isSelected,
                    preferBelow: false,
                    child: FlowyText.emoji(
                      emoji,
                      fontSize: configuration.emojiSize,
                    ),
                  ),
                  onTap: () => onSelect(index),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void changeSelectedIndex(int index) => selectedIndexNotifier.value = index;

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
    if (_search.startsWith(' ')) {
      widget.onDismiss.call();
      return;
    }
    final searchEmojiData = emojiData.filterByKeyword(_search);
    setState(() {
      searchedEmojis.clear();
      searchedEmojis.addAll(searchEmojiData.emojis.values);
      changeSelectedIndex(0);
      _scrollToItem();
    });
    if (searchedEmojis.isEmpty) {
      widget.onDismiss.call();
    }
  }

  KeyEventResult onKeyEvent(focus, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }

    const moveKeys = [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.arrowLeft,
      LogicalKeyboardKey.arrowRight,
    ];

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      onSelect(selectedIndexNotifier.value);
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
        !moveKeys.contains(event.logicalKey)) {
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
      focusNode.requestFocus();

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
    final index = selectedIndexNotifier.value,
        perLine = configuration.perLine,
        remainder = index % perLine,
        length = searchedEmojis.length,
        currentLine = index ~/ perLine,
        maxLine = (length / perLine).ceil();

    final heightBefore = currentLine * emojiHeight;
    if (key == LogicalKeyboardKey.arrowUp) {
      if (currentLine == 0) {
        final exceptLine = max(0, maxLine - 1);
        changeSelectedIndex(min(exceptLine * perLine + remainder, length - 1));
      } else if (currentLine > 0) {
        changeSelectedIndex(index - perLine);
      }
    } else if (key == LogicalKeyboardKey.arrowDown) {
      if (currentLine == maxLine - 1) {
        changeSelectedIndex(remainder);
      } else if (currentLine < maxLine - 1) {
        changeSelectedIndex(min(index + perLine, length - 1));
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      if (index == 0) {
        changeSelectedIndex(length - 1);
      } else if (index > 0) {
        changeSelectedIndex(index - 1);
      }
    } else if (key == LogicalKeyboardKey.arrowRight) {
      if (index == length - 1) {
        changeSelectedIndex(0);
      } else if (index < length - 1) {
        changeSelectedIndex(index + 1);
      }
    }
    final heightAfter =
        (selectedIndexNotifier.value ~/ configuration.perLine) * emojiHeight;

    if (mounted && (heightAfter != heightBefore)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToItem();
      });
    }
  }

  void _scrollToItem() {
    final noEmojis = searchedEmojis.isEmpty;
    if (noEmojis || !mounted) return;
    final currentItem = selectedIndexNotifier.value;
    final exceptHeight = (currentItem ~/ configuration.perLine) * emojiHeight;
    final maxExtent = scrollController.position.maxScrollExtent;
    final jumpTo = (exceptHeight - maxExtent > 10 * emojiHeight)
        ? exceptHeight
        : min(exceptHeight, maxExtent);
    scrollController.animateTo(
      jumpTo,
      duration: Duration(milliseconds: 300),
      curve: Curves.linear,
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
