import 'package:app_flowy/workspace/presentation/plugins/grid/src/layout/sizes.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final theme = context.watch<AppTheme>();
    final borderSide = BorderSide(color: theme.shader4, width: 0.4);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {},
      child: Container(
        constraints: BoxConstraints(
          maxWidth: width,
        ),
        decoration: BoxDecoration(
          border: Border(right: borderSide, bottom: borderSide),
        ),
        padding: GridSize.cellContentInsets,
        child: Center(child: IntrinsicHeight(child: child)),
      ),
    );
  }
}
