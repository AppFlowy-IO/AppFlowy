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
  });

  final List<Widget> avatars;

  final Positions? settings;

  final InfoWidgetBuilder? infoWidgetBuilder;

  final double? width;

  final double? height;

  final double? borderWidth;

  final Color? borderColor;

  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final settings = this.settings ??
        RestrictedPositions(
          maxCoverage: 0.3,
          minCoverage: 0.1,
          align: StackAlign.right,
        );

    final border = BorderSide(
      color: borderColor ?? Theme.of(context).colorScheme.onPrimary,
      width: borderWidth ?? 2.0,
    );

    Widget textInfoWidgetBuilder(surplus) => BorderedCircleAvatar(
          border: border,
          backgroundColor: backgroundColor,
          child: FittedBox(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '+$surplus',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        );
    final infoWidgetBuilder = this.infoWidgetBuilder ?? textInfoWidgetBuilder;

    return SizedBox(
      height: height,
      width: width,
      child: WidgetStack(
        positions: settings,
        buildInfoWidget: infoWidgetBuilder,
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
