import 'dart:async';

import 'package:appflowy/mobile/presentation/selection_menu/mobile_selection_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_result.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_service.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import 'mobile_inline_actions_menu_group.dart';

extension _StartWithsSort on List<InlineActionsResult> {
  void sortByStartsWithKeyword(String search) => sort(
        (a, b) {
          final aCount = a.startsWithKeywords
                  ?.where(
                    (key) => search.toLowerCase().startsWith(key),
                  )
                  .length ??
              0;

          final bCount = b.startsWithKeywords
                  ?.where(
                    (key) => search.toLowerCase().startsWith(key),
                  )
                  .length ??
              0;

          if (aCount > bCount) {
            return -1;
          } else if (bCount > aCount) {
            return 1;
          }

          return 0;
        },
      );
}

const _invalidSearchesAmount = 10;

class MobileInlineActionsHandler extends StatefulWidget {
  const MobileInlineActionsHandler({
    super.key,
    required this.results,
    required this.editorState,
    required this.menuService,
    required this.onDismiss,
    required this.style,
    required this.service,
    this.startCharAmount = 1,
    this.startOffset = 0,
    this.cancelBySpaceHandler,
  });

  final List<InlineActionsResult> results;
  final EditorState editorState;
  final InlineActionsMenuService menuService;
  final VoidCallback onDismiss;
  final InlineActionsMenuStyle style;
  final int startCharAmount;
  final InlineActionsService service;
  final bool Function()? cancelBySpaceHandler;
  final int startOffset;

  @override
  State<MobileInlineActionsHandler> createState() =>
      _MobileInlineActionsHandlerState();
}

class _MobileInlineActionsHandlerState
    extends State<MobileInlineActionsHandler> {
  final _focusNode =
      FocusNode(debugLabel: 'mobile_inline_actions_menu_handler');

  late List<InlineActionsResult> results = widget.results;
  int invalidCounter = 0;
  late int startOffset;

  String _search = '';

  set search(String search) {
    _search = search;
    _doSearch();
  }

  Future<void> _doSearch() async {
    final List<InlineActionsResult> newResults = [];
    for (final handler in widget.service.handlers) {
      final group = await handler.search(_search);

      if (group.results.isNotEmpty) {
        newResults.add(group);
      }
    }

    invalidCounter = results.every((group) => group.results.isEmpty)
        ? invalidCounter + 1
        : 0;

    if (invalidCounter >= _invalidSearchesAmount) {
      widget.onDismiss();

      // Workaround to bring focus back to editor
      await editorState.updateSelectionWithReason(editorState.selection);

      return;
    }

    _resetSelection();

    newResults.sortByStartsWithKeyword(_search);
    setState(() => results = newResults);
  }

  void _resetSelection() {
    _selectedGroup = 0;
    _selectedIndex = 0;
  }

  int _selectedGroup = 0;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );

    startOffset = editorState.selection?.endIndex ?? 0;
    keepEditorFocusNotifier.increase();
    editorState.selectionNotifier.addListener(onSelectionChanged);
  }

  @override
  void dispose() {
    editorState.selectionNotifier.removeListener(onSelectionChanged);
    _focusNode.dispose();
    keepEditorFocusNotifier.decrease();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = editorState.renderBox!.size.width - 24 * 2;
    return Focus(
      focusNode: _focusNode,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: 192,
          minWidth: width,
          maxWidth: width,
        ),
        margin: EdgeInsets.symmetric(horizontal: 24.0),
        decoration: BoxDecoration(
          color: widget.style.backgroundColor,
          borderRadius: BorderRadius.circular(6.0),
          boxShadow: [
            BoxShadow(
              blurRadius: 5,
              spreadRadius: 1,
              color: Colors.black.withValues(alpha: 0.1),
            ),
          ],
        ),
        child: noResults
            ? context.buildNoResultWidget()
            : SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: results
                          .where((g) => g.results.isNotEmpty)
                          .mapIndexed(
                            (index, group) => MobileInlineActionsGroup(
                              result: group,
                              editorState: editorState,
                              menuService: menuService,
                              style: widget.style,
                              onSelected: widget.onDismiss,
                              startOffset: startOffset - widget.startCharAmount,
                              endOffset:
                                  _search.length + widget.startCharAmount,
                              isLastGroup: index == results.length - 1,
                              isGroupSelected: _selectedGroup == index,
                              selectedIndex: _selectedIndex,
                              onPreSelect: (int value) {
                                setState(() {
                                  _selectedGroup = index;
                                  _selectedIndex = value;
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  bool get noResults =>
      results.isEmpty || results.every((e) => e.results.isEmpty);

  int get groupLength => results.length;

  int lengthOfGroup(int index) =>
      results.length > index ? results[index].results.length : -1;

  InlineActionsMenuItem handlerOf(int groupIndex, int handlerIndex) =>
      results[groupIndex].results[handlerIndex];

  EditorState get editorState => widget.editorState;

  InlineActionsMenuService get menuService => widget.menuService;

  void onSelectionChanged() {
    final selection = editorState.selection;
    if (selection == null) {
      menuService.dismiss();
      return;
    }
    if (!selection.isCollapsed) {
      menuService.dismiss();
      return;
    }
    final startOffset = widget.startOffset;
    final endOffset = selection.end.offset;
    if (endOffset < startOffset) {
      menuService.dismiss();
      return;
    }
    final node = editorState.getNodeAtPath(selection.start.path);
    final text = node?.delta?.toPlainText() ?? '';
    final search = text.substring(startOffset, endOffset);
    this.search = search;
  }
}
