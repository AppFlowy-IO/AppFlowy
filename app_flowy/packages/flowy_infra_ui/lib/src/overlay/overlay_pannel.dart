import 'dart:ui' show window;

import 'package:flutter/material.dart';

import 'overlay_basis.dart';
import 'overlay_layout_delegate.dart';

class OverlayPannel extends StatefulWidget {
  const OverlayPannel({
    Key? key,
    this.focusNode,
  }) : super(key: key);

  final FocusNode? focusNode;

  @override
  _OverlayPannelState createState() => _OverlayPannelState();
}

class _OverlayPannelState extends State<OverlayPannel> with WidgetsBindingObserver {
  FocusNode? _internalNode;
  FocusNode? get focusNode => widget.focusNode ?? _internalNode;
  late FocusHighlightMode _focusHighlightMode;
  bool _hasPrimaryFocus = false;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalNode ??= _createFocusNode();
    }
    focusNode!.addListener(_handleFocusChanged);
    final FocusManager focusManager = WidgetsBinding.instance!.focusManager;
    _focusHighlightMode = focusManager.highlightMode;
    focusManager.addHighlightModeListener(_handleFocusHighlightModeChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    focusNode!.removeListener(_handleFocusChanged);
    WidgetsBinding.instance!.focusManager.removeHighlightModeListener(_handleFocusHighlightModeChanged);
    _internalNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  @override
  void didUpdateWidget(OverlayPannel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode?.removeListener(_handleFocusChanged);
      if (widget.focusNode == null) {
        _internalNode ??= _createFocusNode();
      }
      _hasPrimaryFocus = focusNode!.hasPrimaryFocus;
      focusNode!.addListener(_handleFocusChanged);
    }
  }

  // MARK: Focus & Route

  FocusNode _createFocusNode() {
    return FocusNode(debugLabel: '${widget.runtimeType}');
  }

  void _handleFocusChanged() {
    if (_hasPrimaryFocus != focusNode!.hasPrimaryFocus) {
      setState(() {
        _hasPrimaryFocus = focusNode!.hasPrimaryFocus;
      });
    }
  }

  void _handleFocusHighlightModeChanged(FocusHighlightMode mode) {
    if (!mounted) {
      return;
    }
    setState(() {
      _focusHighlightMode = mode;
    });
  }

  void _removeOverlayRoute() {
    // TODO: junlin
  }

  // MARK: Layout

  Orientation _getOrientation(BuildContext context) {
    Orientation? result = MediaQuery.maybeOf(context)?.orientation;
    if (result == null) {
      // If there's no MediaQuery, then use the window aspect to determine
      // orientation.
      final Size size = window.physicalSize;
      result = size.width > size.height ? Orientation.landscape : Orientation.portrait;
    }
    return result;
  }
}
