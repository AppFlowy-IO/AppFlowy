import 'dart:math';
import 'package:appflowy/features/mension_person/data/models/mention_menu_item.dart';
import 'package:appflowy/features/mension_person/logic/mention_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../mention_menu_service.dart';

class MentionMenuShortcuts extends StatefulWidget {
  const MentionMenuShortcuts({
    super.key,
    required this.child,
    required this.scrollController,
    required this.itemMap,
  });

  final Widget child;
  final ScrollController scrollController;
  final MentionItemMap itemMap;
  @override
  State<MentionMenuShortcuts> createState() => _MentionMenuShortcutsState();
}

class _MentionMenuShortcutsState extends State<MentionMenuShortcuts> {
  final focusNode = FocusNode();
  int startOffset = 0;

  ScrollController get scrollController => widget.scrollController;

  MentionItemMap get itemMap => widget.itemMap;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusNode.requestFocus();
      final mentionMenuServiceInfo = context.read<MentionMenuServiceInfo?>();
      startOffset =
          mentionMenuServiceInfo?.editorState.selection?.endIndex ?? 0;
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
      onKeyEvent: (node, event) => onKeyEvent(node, event, context),
      child: widget.child,
    );
  }

  KeyEventResult onKeyEvent(
    FocusNode node,
    KeyEvent event,
    BuildContext context,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final menuBloc = context.read<MentionBloc>(),
        menuState = menuBloc.state,
        queryText = menuState.query;
    final mentionMenuServiceInfo = context.read<MentionMenuServiceInfo>();
    final editorState = mentionMenuServiceInfo.editorState,
        onDismiss = mentionMenuServiceInfo.onDismiss;
    const moveKeys = [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.tab,
    ];

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final item =
          itemMap.items.where((e) => e.id == menuState.selectedId).firstOrNull;
      if (item != null) {
        item.onExecute.call();
      } else {
        onDismiss();
      }
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      // Workaround to bring focus back to editor
      editorState.updateSelectionWithReason(editorState.selection);
      onDismiss();
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (queryText.isEmpty) {
        if (_canDeleteLastCharacter(context)) {
          editorState.deleteBackward();
        } else {
          // Workaround for editor regaining focus
          editorState.apply(
            editorState.transaction..afterSelection = editorState.selection,
          );
        }
        onDismiss();
      } else {
        // widget.onSelectionUpdate();
        editorState.deleteBackward();
        _deleteCharacterAtSelection(context);
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
      // widget.onSelectionUpdate();

      // Interpolation to avoid having a getter for private variable
      _insertCharacter(event.character!, context);
      return KeyEventResult.handled;
    } else if (moveKeys.contains(event.logicalKey)) {
      _moveSelection(event.logicalKey, context);
      return KeyEventResult.handled;
    }

    if ([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight]
        .contains(event.logicalKey)) {
      // widget.onSelectionUpdate();

      event.logicalKey == LogicalKeyboardKey.arrowLeft
          ? editorState.moveCursorForward()
          : editorState.moveCursorBackward(SelectionMoveRange.character);

      /// If cursor moves before @ then dismiss menu
      /// If cursor moves after @search.length then dismiss menu
      final selection = editorState.selection;
      if (selection != null &&
          (selection.endIndex < startOffset ||
              selection.endIndex > (startOffset + queryText.length))) {
        onDismiss();
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

  void _moveSelection(LogicalKeyboardKey key, BuildContext context) {
    final menuBloc = context.read<MentionBloc>(), menuState = menuBloc.state;
    final items = itemMap.items;
    final index = items.indexWhere((e) => e.id == menuState.selectedId);
    int newIndex = index;
    final isUp = key == LogicalKeyboardKey.arrowUp ||
        (key == LogicalKeyboardKey.tab &&
            HardwareKeyboard.instance.isShiftPressed);
    final isDown =
        [LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.tab].contains(key);
    if (!isUp && !isDown) return;
    if (index < 0) {
      newIndex = isUp ? items.length - 1 : 0;
    } else {
      if (isUp) {
        newIndex = index == 0 ? items.length - 1 : index - 1;
      } else if (isDown) {
        newIndex = index == items.length - 1 ? 0 : index + 1;
      }
    }
    final item = items[newIndex];
    menuBloc.add(MentionEvent.selectItem(item.id));
    _scrollToItem(index, newIndex, context);
  }

  void _scrollToItem(
    int from,
    int to,
    BuildContext context,
  ) {
    if (!context.mounted) return;
    final items = itemMap.items;

    /// scroll to the end
    if (to == items.length - 1) {
      scrollController.jumpTo(scrollController.position.maxScrollExtent);
      return;
    } else if (to == 0) {
      /// scroll to the start
      scrollController.jumpTo(0);
      return;
    }

    final menuInfo = context.read<MentionMenuServiceInfo>();
    final toId = items[to].id, isTopArea = menuInfo.isTopArea(toId);

    final currentPosition = scrollController.position.pixels;
    if (isTopArea && from > to) {
      scrollController.jumpTo(max(0, currentPosition - 50));
    } else if (!isTopArea && from < to) {
      scrollController.jumpTo(
        min(currentPosition + 50, scrollController.position.maxScrollExtent),
      );
    }
  }

  void _insertCharacter(String character, BuildContext context) {
    final menuBloc = context.read<MentionBloc>(), menuState = menuBloc.state;
    final mentionMenuServiceInfo = context.read<MentionMenuServiceInfo>();
    final editorState = mentionMenuServiceInfo.editorState;
    editorState.insertTextAtCurrentSelection(character);

    final selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return;
    }

    final delta = editorState.getNodeAtPath(selection.end.path)?.delta;
    if (delta == null) {
      return;
    }

    final oldText = menuState.query;

    final query = editorState
        .getTextInSelection(
          selection.copyWith(
            start: selection.start.copyWith(offset: startOffset),
            end: selection.start
                .copyWith(offset: startOffset + oldText.length + 1),
          ),
        )
        .join();
    onQuery(context, query);
  }

  bool _canDeleteLastCharacter(BuildContext context) {
    final mentionMenuServiceInfo = context.read<MentionMenuServiceInfo>(),
        editorState = mentionMenuServiceInfo.editorState,
        selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) {
      return false;
    }

    final delta = editorState.getNodeAtPath(selection.start.path)?.delta;
    if (delta == null) {
      return false;
    }

    return delta.isNotEmpty;
  }

  void _deleteCharacterAtSelection(BuildContext context) {
    final menuBloc = context.read<MentionBloc>(), menuState = menuBloc.state;

    final mentionMenuServiceInfo = context.read<MentionMenuServiceInfo>(),
        editorState = mentionMenuServiceInfo.editorState,
        selection = editorState.selection;
    if (selection == null || !selection.isCollapsed) return;

    final node = editorState.getNodeAtPath(selection.end.path);
    final delta = node?.delta;
    if (node == null || delta == null) {
      return;
    }

    final oldText = menuState.query;
    final query = delta.toPlainText().substring(
          startOffset,
          startOffset - 1 + oldText.length,
        );
    onQuery(context, query);
  }

  void onQuery(BuildContext context, String text) =>
      context.read<MentionBloc>().add(MentionEvent.query(text));
}
