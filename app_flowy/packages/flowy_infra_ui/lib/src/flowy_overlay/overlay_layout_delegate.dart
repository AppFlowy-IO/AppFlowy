// import 'dart:math' as math;
// import 'dart:ui';

// import 'package:flutter/material.dart';

// import 'flowy_overlay.dart';

// class OverlayLayoutDelegate extends SingleChildLayoutDelegate {
//   OverlayLayoutDelegate({
//     required this.route,
//     required this.padding,
//     required this.anchorPosition,
//     required this.anchorDirection,
//   });

//   final OverlayPannelRoute route;
//   final EdgeInsets padding;
//   final AnchorDirection anchorDirection;
//   final Offset anchorPosition;

//   @override
//   bool shouldRelayout(OverlayLayoutDelegate oldDelegate) {
//     return anchorPosition != oldDelegate.anchorPosition || anchorDirection != oldDelegate.anchorDirection;
//   }

//   @override
//   Offset getPositionForChild(Size size, Size childSize) {
//     // TODO: junlin - calculate child position
//     return Offset.zero;
//   }

//   @override
//   BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
//     double maxHeight = math.max(0.0, constraints.maxHeight - padding.top - padding.bottom);
//     double width = constraints.maxWidth;
//     return BoxConstraints(
//       minHeight: 0.0,
//       maxHeight: maxHeight,
//       minWidth: width,
//       maxWidth: width,
//     );
//   }
// }
