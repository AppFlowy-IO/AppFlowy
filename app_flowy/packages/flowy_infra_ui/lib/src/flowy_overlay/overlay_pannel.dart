// import 'dart:ui' show window;

// import 'package:flowy_infra_ui/src/overlay/overlay_route.dart';
// import 'package:flutter/material.dart';

// import 'overlay_.dart';

// class OverlayPannel extends StatefulWidget {
//   const OverlayPannel({
//     Key? key,
//     this.focusNode,
//     this.padding = EdgeInsets.zero,
//     this.anchorDirection = AnchorDirection.topRight,
//     required this.anchorPosition,
//     required this.route,
//   }) : super(key: key);

//   final FocusNode? focusNode;
//   final EdgeInsetsGeometry padding;
//   final AnchorDirection anchorDirection;
//   final Offset anchorPosition;
//   final OverlayPannelRoute route;

//   @override
//   _OverlayPannelState createState() => _OverlayPannelState();
// }

// class _OverlayPannelState extends State<OverlayPannel> with WidgetsBindingObserver {
//   FocusNode? _internalNode;
//   FocusNode? get focusNode => widget.focusNode ?? _internalNode;
//   late FocusHighlightMode _focusHighlightMode;
//   bool _hasPrimaryFocus = false;
//   late CurvedAnimation _fadeOpacity;
//   late CurvedAnimation _resize;
//   OverlayPannelRoute? _overlayRoute;

//   @override
//   void initState() {
//     super.initState();
//     _fadeOpacity = CurvedAnimation(
//       parent: widget.route.animation!,
//       curve: const Interval(0.0, 0.25),
//       reverseCurve: const Interval(0.75, 1.0),
//     );
//     _resize = CurvedAnimation(
//       parent: widget.route.animation!,
//       curve: const Interval(0.25, 0.5),
//       reverseCurve: const Threshold(0.0),
//     );

//     // TODO: junlin - handle focus action or remove it
//     if (widget.focusNode == null) {
//       _internalNode ??= _createFocusNode();
//     }
//     focusNode!.addListener(_handleFocusChanged);
//     final FocusManager focusManager = WidgetsBinding.instance!.focusManager;
//     _focusHighlightMode = focusManager.highlightMode;
//     focusManager.addHighlightModeListener(_handleFocusHighlightModeChanged);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance!.removeObserver(this);
//     focusNode!.removeListener(_handleFocusChanged);
//     WidgetsBinding.instance!.focusManager.removeHighlightModeListener(_handleFocusHighlightModeChanged);
//     _internalNode?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return FadeTransition(
//       opacity: _fadeOpacity,
//     );
//   }

//   @override
//   void didUpdateWidget(OverlayPannel oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (widget.focusNode != oldWidget.focusNode) {
//       oldWidget.focusNode?.removeListener(_handleFocusChanged);
//       if (widget.focusNode == null) {
//         _internalNode ??= _createFocusNode();
//       }
//       _hasPrimaryFocus = focusNode!.hasPrimaryFocus;
//       focusNode!.addListener(_handleFocusChanged);
//     }
//   }

//   // MARK: Focus & Route

//   FocusNode _createFocusNode() {
//     return FocusNode(debugLabel: '${widget.runtimeType}');
//   }

//   void _handleFocusChanged() {
//     if (_hasPrimaryFocus != focusNode!.hasPrimaryFocus) {
//       setState(() {
//         _hasPrimaryFocus = focusNode!.hasPrimaryFocus;
//       });
//     }
//   }

//   void _handleFocusHighlightModeChanged(FocusHighlightMode mode) {
//     if (!mounted) {
//       return;
//     }
//     setState(() {
//       _focusHighlightMode = mode;
//     });
//   }

//   // MARK: Layout

//   Orientation _getOrientation(BuildContext context) {
//     Orientation? result = MediaQuery.maybeOf(context)?.orientation;
//     if (result == null) {
//       final Size size = window.physicalSize;
//       result = size.width > size.height ? Orientation.landscape : Orientation.portrait;
//     }
//     return result;
//   }
// }
