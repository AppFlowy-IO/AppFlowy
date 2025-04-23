import 'package:appflowy_ui/appflowy_ui.dart';
import 'package:flutter/widgets.dart';

class AFDivider extends StatelessWidget {
  const AFDivider({
    super.key,
    this.axis = Axis.horizontal,
    this.color,
    this.thickness = 1.0,
    this.spacing = 0.0,
    this.startIndent = 0.0,
    this.endIndent = 0.0,
  })  : assert(thickness > 0.0),
        assert(spacing >= 0.0),
        assert(startIndent >= 0.0),
        assert(endIndent >= 0.0);

  final Axis axis;
  final double thickness;
  final double spacing;
  final double startIndent;
  final double endIndent;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = AppFlowyTheme.of(context);
    final color = this.color ?? theme.borderColorScheme.greyTertiary;

    return switch (axis) {
      Axis.horizontal => Container(
          height: thickness,
          color: color,
          margin: EdgeInsetsDirectional.only(
            start: startIndent,
            end: endIndent,
            top: spacing,
            bottom: spacing,
          ),
        ),
      Axis.vertical => Container(
          width: thickness,
          color: color,
          margin: EdgeInsets.only(
            left: spacing,
            right: spacing,
            top: startIndent,
            bottom: endIndent,
          ),
        ),
    };
  }
}
