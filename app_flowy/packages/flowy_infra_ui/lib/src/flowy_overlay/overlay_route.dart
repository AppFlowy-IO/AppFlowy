// import 'package:flutter/material.dart';

// class _OverlayRouteResult {}

// const Duration _kOverlayDuration = Duration(milliseconds: 0);

// class OverlayPannelRoute extends PopupRoute<_OverlayRouteResult> {
//   OverlayPannelRoute({
//     this.barrierColor,
//     required this.barrierLabel,
//   });

//   @override
//   bool get barrierDismissible => true;

//   @override
//   Color? barrierColor;

//   @override
//   String? barrierLabel;

//   @override
//   Duration get transitionDuration => _kOverlayDuration;

//   @override
//   Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
//     return LayoutBuilder(builder: (context, contraints) {
//       return const _OverlayRoutePage();
//     });
//   }
// }

// class _OverlayRoutePage extends StatelessWidget {
//   const _OverlayRoutePage({
//     Key? key,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     assert(debugCheckHasDirectionality(context));
//     final TextDirection? textDirection = Directionality.maybeOf(context);
//     // TODO: junlin - Use overlay pannel to manage focus node

//     return MediaQuery.removePadding(
//       context: context,
//       removeTop: true,
//       removeBottom: true,
//       removeLeft: true,
//       removeRight: true,
//       child: Container(
//         color: Colors.blue[100],
//       ),
//     );
//   }
// }
