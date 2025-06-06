import 'dart:async';

import 'package:appflowy/plugins/document/application/document_bloc.dart';
import 'package:appflowy/plugins/inline_actions/inline_actions_menu.dart';
import 'package:appflowy/user/application/reminder/reminder_bloc.dart';
import 'package:appflowy/workspace/application/user/user_workspace_bloc.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import 'mention_menu.dart';

class MentionMenuService extends InlineActionsMenuService {
  MentionMenuService({
    required this.context,
    required this.editorState,
    required this.workspaceBloc,
    required this.documentBloc,
    required this.reminderBloc,
    this.startCharAmount = 1,
  });

  final BuildContext context;
  final EditorState editorState;
  final UserWorkspaceBloc workspaceBloc;
  final DocumentBloc documentBloc;
  final ReminderBloc reminderBloc;
  final int startCharAmount;

  OverlayEntry? _menuEntry;
  Offset _offset = Offset.zero;
  Alignment _alignment = Alignment.topLeft;
  bool selectionChangedByMenu = false;

  @override
  void dismiss() {
    if (_menuEntry != null) {
      editorState.service.keyboardService?.enable();
      editorState.service.scrollService?.enable();
      keepEditorFocusNotifier.decrease();
    }

    _menuEntry?.remove();
    _menuEntry = null;

    // workaround: SelectionService has been released after hot reload.
    final isSelectionDisposed =
        editorState.service.selectionServiceKey.currentState == null;
    if (!isSelectionDisposed) {
      final selectionService = editorState.service.selectionService;
      selectionService.currentSelection.removeListener(_onSelectionChange);
    }
  }

  @override
  Future<void> show() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _show();
      completer.complete();
    });
    return completer.future;
  }

  @override
  InlineActionsMenuStyle get style => throw UnimplementedError();

  void _show() {
    dismiss();

    final selectionService = editorState.service.selectionService;
    final selectionRects = selectionService.selectionRects;
    if (selectionRects.isEmpty) {
      return;
    }

    calculateSelectionMenuOffset(selectionRects.first);
    final (left, top, right, bottom) = _getPosition(_alignment, _offset);

    final editorHeight = editorState.renderBox!.size.height;
    final editorWidth = editorState.renderBox!.size.width;
    _menuEntry = OverlayEntry(
      builder: (context) => SizedBox(
        height: editorHeight,
        width: editorWidth,

        // GestureDetector handles clicks outside of the context menu,
        // to dismiss the context menu.
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: dismiss,
          child: Stack(
            children: [
              Positioned(
                top: top,
                bottom: bottom,
                left: left,
                right: right,
                child: MultiBlocProvider(
                  providers: [
                    BlocProvider.value(value: workspaceBloc),
                    BlocProvider.value(value: documentBloc),
                    BlocProvider.value(value: reminderBloc),
                  ],
                  child: BlocBuilder<UserWorkspaceBloc, UserWorkspaceState>(
                    builder: (_, __) => Provider(
                      create: (_) => MentionMenuServiceInfo(
                        onDismiss: dismiss,
                        startCharAmount: startCharAmount,
                        startOffset: editorState.selection?.endIndex ?? 0,
                        editorState: editorState,
                        top: top ?? (editorHeight - (bottom ?? 0.0) - 400),
                      ),
                      dispose: (context, value) => value._dispose(),
                      child: MentionMenu(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_menuEntry!);

    editorState.service.keyboardService?.disable(showCursor: true);
    editorState.service.scrollService?.disable();
    selectionService.currentSelection.addListener(_onSelectionChange);
  }

  void calculateSelectionMenuOffset(Rect rect) {
    const menuHeight = 400.0, menuWidth = 400.0;
    const menuOffset = Offset(0, 0);
    final editorOffset =
        editorState.renderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final editorHeight = editorState.renderBox!.size.height;
    final editorWidth = editorState.renderBox!.size.width;

    // show below default
    _alignment = Alignment.topLeft;
    final bottomRight = rect.bottomRight, topRight = rect.topRight;
    var offset = bottomRight + menuOffset;
    _offset = Offset(offset.dx, offset.dy);

    // show above
    if (offset.dy + menuHeight >= editorOffset.dy + editorHeight) {
      offset = topRight - menuOffset;
      _alignment = Alignment.bottomLeft;

      _offset = Offset(
        offset.dx,
        editorHeight + editorOffset.dy - offset.dy,
      );
    }

    // show on right
    if (_offset.dx + menuWidth < editorOffset.dx + editorWidth) {
      _offset = Offset(_offset.dx, _offset.dy);
    } else if (offset.dx - editorOffset.dx > menuWidth) {
      // show on left
      _alignment = _alignment == Alignment.topLeft
          ? Alignment.topRight
          : Alignment.bottomRight;

      _offset = Offset(
        editorWidth - _offset.dx + editorOffset.dx,
        _offset.dy,
      );
    }
  }

  (double? left, double? top, double? right, double? bottom) _getPosition(
    Alignment alignment,
    Offset offset,
  ) {
    double? left, top, right, bottom;
    switch (alignment) {
      case Alignment.topLeft:
        left = offset.dx;
        top = offset.dy;
        break;
      case Alignment.bottomLeft:
        left = offset.dx;
        bottom = offset.dy;
        break;
      case Alignment.topRight:
        right = offset.dx;
        top = offset.dy;
        break;
      case Alignment.bottomRight:
        right = offset.dx;
        bottom = offset.dy;
        break;
    }

    return (left, top, right, bottom);
  }

  void _onSelectionChange() {
    // workaround: SelectionService has been released after hot reload.
    final isSelectionDisposed =
        editorState.service.selectionServiceKey.currentState == null;
    if (!isSelectionDisposed) {
      final selectionService = editorState.service.selectionService;
      if (selectionService.currentSelection.value == null) {
        return;
      }
    }

    if (!selectionChangedByMenu) {
      return dismiss();
    }

    selectionChangedByMenu = false;
  }
}

class MentionMenuServiceInfo {
  MentionMenuServiceInfo({
    required this.onDismiss,
    required this.startCharAmount,
    required this.startOffset,
    required this.editorState,
    required this.top,
  });

  final VoidCallback onDismiss;
  final int startCharAmount;
  final int startOffset;
  final EditorState editorState;
  final double top;
  final Map<String, ValueGetter<double>> _itemYMap = {};

  void addItemHeightGetter(String id, ValueGetter<double> yGetter) {
    _itemYMap[id] = yGetter;
  }

  void removeItemHeightGetter(String id) => _itemYMap.remove(id);

  void _dispose() {
    _itemYMap.clear();
  }

  double? getItemPositionY(String id) => _itemYMap[id]?.call();

  bool isTopArea(String id) {
    final itemY = getItemPositionY(id);
    if (itemY == null) return false;
    return itemY <= top + 200;
  }

  TextRange textRange(String queryText) => TextRange(
        start: startOffset - startCharAmount,
        end: queryText.length + startCharAmount,
      );
}
