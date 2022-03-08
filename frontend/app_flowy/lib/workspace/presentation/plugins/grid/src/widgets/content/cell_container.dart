import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flutter/material.dart';

class CellContainer extends StatelessWidget {
  final Widget child;
  final double width;
  const CellContainer({
    Key? key,
    required this.child,
    required this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {},
      child: Container(
        constraints: BoxConstraints(
          maxWidth: width,
        ),
        padding: EdgeInsets.symmetric(vertical: GridInsets.vertical, horizontal: GridInsets.horizontal),
        child: Center(child: IntrinsicHeight(child: child)),
      ),
    );
  }
}
