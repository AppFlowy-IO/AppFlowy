import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_command.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy/plugins/inline_actions/widgets/inline_actions_menu_group.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// TODO(Xazin): Dismiss context menu on too many invalid searches
///  Maybe?: consider logic for keepAlive requests from delegate (?)
// const _invalidSearchesAmount = 3;

class InlineActionsHandler extends StatefulWidget {
  const InlineActionsHandler({
    super.key,
    required this.service,
    required this.results,
    required this.editorState,
    required this.menuService,
    required this.onDismiss,
    required this.onSelectionUpdate,
    required this.style,
  });

  final InlineActionsService service;
  final List<InlineActionsResult> results;
  final EditorState editorState;
  final InlineActionsMenuService menuService;
  final VoidCallback onDismiss;
  final VoidCallback onSelectionUpdate;
  final InlineActionsMenuStyle style;

  @override
  State<InlineActionsHandler> createState() => _InlineActionsHandlerState();
}

class _InlineActionsHandlerState extends State<InlineActionsHandler> {
  final _focusNode = FocusNode(debugLabel: 'inline_actions_menu_handler');

  List<InlineActionsResult> results = [];
  int invalidCounter = 0;

  String _search = '';
  set search(String search) {
    _search = search;
    _doSearch();
  }

  Future<void> _doSearch() async {
    final List<InlineActionsResult> newResults = [];
    for (final handler in widget.service.handlers) {
      final group = await handler.call(_search);

      if (group.results.isNotEmpty) {
        newResults.add(group);
      }
    }

    setState(() {
      results = newResults;
    });
  }

  int _searchLength = 0;

  int _selectedGroup = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    results = widget.results;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKey: onKey,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: widget.style.backgroundColor,
          borderRadius: BorderRadius.circular(6.0),
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              spreadRadius: 1,
              color: Colors.black.withOpacity(0.1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: noResults
              ? SizedBox(
                  width: 150,
                  child: FlowyText.regular(
                    LocaleKeys.inlineActions_noResults.tr(),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: results
                      .mapIndexed(
                        (index, group) => InlineActionsGroup(
                          result: group,
                          editorState: widget.editorState,
                          menuService: widget.menuService,
                          style: widget.style,
                          isGroupSelected: _selectedGroup == index,
                          selectedIndex: _selectedIndex,
                          onSelected: widget.onDismiss,
                        ),
                      )
                      .toList(),
                ),
        ),
      ),
    );
  }

  bool get noResults =>
      results.isEmpty || results.every((e) => e.results.isEmpty);

  int get groupLength => results.length;

  int lengthOfGroup(int index) => results[index].results.length;

  InlineActionsMenuItem handlerOf(int groupIndex, int handlerIndex) =>
      results[groupIndex].results[handlerIndex];

  KeyEventResult onKey(focus, event) {
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }

    const moveKeys = [
      LogicalKeyboardKey.arrowUp,
      LogicalKeyboardKey.arrowDown,
      LogicalKeyboardKey.tab,
    ];

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_selectedGroup <= groupLength &&
          _selectedIndex <= lengthOfGroup(_selectedGroup)) {
        handlerOf(
          _selectedGroup,
          _selectedIndex,
        ).onSelected?.call(
              context,
              widget.editorState,
              widget.menuService,
            );

        widget.onDismiss();
        return KeyEventResult.handled;
      }
    } else if (event.logicalKey == LogicalKeyboardKey.escape) {
      widget.onDismiss();
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_search.isEmpty) {
        widget.onDismiss();
      } else {
        search = _search.substring(0, _search.length - 1);
      }

      /// Prevents dismissal of context menu by notifying the parent
      /// that the selection change occurred from the handler.
      widget.onSelectionUpdate();

      /// TODO(Xazin): Consider delete word backward with CTRL+BACKSPACE
      widget.editorState.deleteBackward();
      return KeyEventResult.handled;
    } else if (event.character != null &&
        !moveKeys.contains(event.logicalKey)) {
      /// Prevents dismissal of context menu by notifying the parent
      /// that the selection change occurred from the handler.
      widget.onSelectionUpdate();

      // Interpolation to avoid having a getter for private variable
      _insertCharacter(event.character!);

      return KeyEventResult.handled;
    }

    if (moveKeys.contains(event.logicalKey)) {
      _moveSelection(event.logicalKey);

      return KeyEventResult.handled;
    }

    if ([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.arrowRight]
        .contains(event.logicalKey)) {
      widget.onSelectionUpdate();
      event.logicalKey == LogicalKeyboardKey.arrowLeft
          ? widget.editorState.moveCursorForward(SelectionMoveRange.character)
          : widget.editorState.moveCursorBackward(SelectionMoveRange.character);

      /// Workaround: When using the move cursor methods, it seems the
      ///  focus goes back to the editor, this makes sure this handler
      ///  receives the next keypress.
      ///
      _focusNode.requestFocus();

      return KeyEventResult.handled;
    }

    return KeyEventResult.handled;
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

    // Increase length of search term
    _searchLength += 1;

    /// Grab index of the first character in command (right after @)
    final startIndex =
        delta.toPlainText().lastIndexOf(inlineActionCharacter) + 1;

    search = widget.editorState
        .getTextInSelection(
          selection.copyWith(
            start: selection.start.copyWith(offset: startIndex),
            end: selection.start.copyWith(offset: startIndex + _searchLength),
          ),
        )
        .join();
  }

  void _moveSelection(LogicalKeyboardKey key) {
    if ([LogicalKeyboardKey.arrowDown, LogicalKeyboardKey.tab].contains(key)) {
      if (_selectedIndex < lengthOfGroup(_selectedGroup) - 1) {
        _selectedIndex += 1;
      } else if (_selectedGroup < groupLength - 1) {
        _selectedGroup += 1;
        _selectedIndex = 0;
      }
    } else if (key == LogicalKeyboardKey.arrowUp) {
      if (_selectedIndex == 0 && _selectedGroup > 0) {
        _selectedGroup -= 1;
      } else if (_selectedIndex > 0) {
        _selectedIndex -= 1;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }
}
