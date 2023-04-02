import 'dart:async';

import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/material.dart';

class FloatingToolbar extends StatefulWidget {
  const FloatingToolbar({
    super.key,
    required this.editorState,
    required this.child,
  });

  final EditorState editorState;
  final Widget child;

  @override
  State<FloatingToolbar> createState() => _FloatingToolbarState();
}

class _FloatingToolbarState extends State<FloatingToolbar> {
  OverlayEntry? _toolbarEntry;
  Selection? _cacheSelection;
  List<Node> _cacheVisibleSelectedNodes = [];
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      widget.editorState.service.selectionServiceV2
          .addListener(_onSelectionChanged);
      widget.editorState.service.scrollServiceV2.scrollController
          .addListener(_scrollListener);
    });
  }

  @override
  void dispose() {
    widget.editorState.service.scrollServiceV2.scrollController
        .removeListener(_scrollListener);
    widget.editorState.service.selectionServiceV2
        .removeListener(_onSelectionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _onSelectionChanged() {
    final selection = widget.editorState.service.selectionServiceV2.selection;
    if (selection == null || selection.isCollapsed) {
      _clear();
      _cacheVisibleSelectedNodes = [];
    } else {
      if (_cacheSelection != selection) {
        _cacheVisibleSelectedNodes = widget.editorState
            .getNodesInSelection(selection)
            .toList(growable: false)
            .normalized;
      }
      _show();
    }
    _cacheSelection = selection;
  }

  void _scrollListener() {
    final offset = widget
        .editorState.service.scrollServiceV2.scrollController.position.pixels;
    print('offset changed $offset');
    _show();
  }

  void _clear() {
    _toolbarEntry?.remove();
    _toolbarEntry = null;
  }

  void _show() {
    _clear();
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      const toolbarHeight = 30.0;
      final visibleNodes =
          widget.editorState.service.selectionServiceV2.visibleNodes;
      final offsets = _cacheVisibleSelectedNodes
          .where((element) => visibleNodes.contains(element))
          .map(
            (element) => element.renderBox?.localToGlobal(Offset.zero),
          );
      // .where((element) => element != null && element.dy >= toolbarHeight);
      if (offsets.isNotEmpty) {
        _toolbarEntry = OverlayEntry(builder: (context) {
          return Positioned(
            top: offsets.first!.dy - toolbarHeight,
            left: offsets.first!.dx,
            child: Container(
              width: 300,
              height: toolbarHeight,
              color: Colors.red,
            ),
          );
        });
        Overlay.of(context)?.insert(_toolbarEntry!);
      }
    });
  }
}
