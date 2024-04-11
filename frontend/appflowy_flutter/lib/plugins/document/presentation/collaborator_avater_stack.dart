import 'package:avatar_stack/avatar_stack.dart';
import 'package:avatar_stack/positions.dart';
import 'package:flutter/material.dart';

class CollaboratorAvatarStack extends StatelessWidget {
  const CollaboratorAvatarStack({
    super.key,
    required this.avatars,
    this.settings,
    this.infoWidgetBuilder,
    this.width,
    this.height,
    this.borderWidth,
    this.borderColor,
    this.backgroundColor,
    required this.plusWidgetBuilder,
  });

  final List<Widget> avatars;

  final Positions? settings;

  final InfoWidgetBuilder? infoWidgetBuilder;

  final double? width;

  final double? height;

  final double? borderWidth;

  final Color? borderColor;

  final Color? backgroundColor;

  final Widget Function(int value, BorderSide border) plusWidgetBuilder;

  @override
  Widget build(BuildContext context) {
    final settings = this.settings ??
        RestrictedPositions(
          maxCoverage: 0.3,
          minCoverage: 0.2,
          align: StackAlign.right,
          laying: StackLaying.first,
        );

    final border = BorderSide(
      color: borderColor ?? Theme.of(context).colorScheme.onPrimary,
      width: borderWidth ?? 2.0,
    );

    return SizedBox(
      height: height,
      width: width,
      child: WidgetStack(
        positions: settings,
        buildInfoWidget: (value) => plusWidgetBuilder(value, border),
        stackedWidgets: avatars
            .map(
              (avatar) => CircleAvatar(
                backgroundColor: border.color,
                child: Padding(
                  padding: EdgeInsets.all(border.width),
                  child: avatar,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
