import 'package:flowy_infra_ui/widget/mouse_hover_builder.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/time/duration.dart';

class StyledHover extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final double borderWidth;
  final Widget child;
  final BorderRadius borderRadius;

  const StyledHover({
    Key? key,
    required this.color,
    required this.child,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
    this.borderRadius = BorderRadius.zero,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MouseHoverBuilder(
      builder: (_, isHovered) => AnimatedContainer(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: borderWidth),
          color: isHovered ? color : Colors.transparent,
          borderRadius: borderRadius,
        ),
        duration: .1.seconds,
        child: child,
      ),
    );
  }
}


// @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       behavior: HitTestBehavior.translucent,
//       onTap: () {
//         context
//             .read<HomeBloc>()
//             .add(HomeEvent.setEditPannel(CellEditPannelContext()));
//       },
//       child: MouseHoverBuilder(
//         builder: (_, isHovered) => Container(
//           width: width,
//           decoration: CellDecoration.box(
//             color: isHovered ? Colors.red.withOpacity(.1) : Colors.transparent,
//           ),
//           padding: EdgeInsets.symmetric(
//               vertical: GridInsets.vertical, horizontal: GridInsets.horizontal),
//           child: child,
//         ),
//       ),
//     );
//   }