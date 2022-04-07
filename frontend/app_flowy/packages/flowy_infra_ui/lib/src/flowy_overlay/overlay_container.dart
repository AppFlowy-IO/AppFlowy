import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

const overlayContainerPadding = EdgeInsets.all(12);

class OverlayContainer extends StatelessWidget {
  final Widget child;
  final BoxConstraints? constraints;
  final EdgeInsets padding;
  const OverlayContainer({
    required this.child,
    this.constraints,
    this.padding = overlayContainerPadding,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<AppTheme>();
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: padding,
        decoration: FlowyDecoration.decoration(theme.surface, theme.shadowColor.withOpacity(0.15)),
        constraints: constraints,
        child: child,
      ),
    );
  }
}
