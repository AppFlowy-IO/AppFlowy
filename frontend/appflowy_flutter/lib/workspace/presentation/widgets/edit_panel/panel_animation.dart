import 'package:flutter/material.dart';

class AnimatedPanel extends StatefulWidget {
  final bool isClosed;
  final double closedX;
  final double closedY;
  final double duration;
  final Curve? curve;
  final Widget? child;

  const AnimatedPanel({
    final Key? key,
    this.isClosed = false,
    this.closedX = 0.0,
    this.closedY = 0.0,
    this.duration = 0.0,
    this.curve,
    this.child,
  }) : super(key: key);

  @override
  AnimatedPanelState createState() => AnimatedPanelState();
}

class AnimatedPanelState extends State<AnimatedPanel> {
  bool _isHidden = true;

  @override
  Widget build(final BuildContext context) {
    final Offset closePos = Offset(widget.closedX, widget.closedY);
    final double duration = _isHidden && widget.isClosed ? 0 : widget.duration;
    return TweenAnimationBuilder(
      curve: widget.curve ?? Curves.easeOut,
      tween: Tween<Offset>(
        begin: !widget.isClosed ? Offset.zero : closePos,
        end: !widget.isClosed ? Offset.zero : closePos,
      ),
      duration: Duration(milliseconds: (duration * 1000).round()),
      builder: (final _, final Offset value, final Widget? c) {
        _isHidden =
            widget.isClosed && value == Offset(widget.closedX, widget.closedY);
        return _isHidden
            ? Container()
            : Transform.translate(offset: value, child: c);
      },
      child: widget.child,
    );
  }
}

extension AnimatedPanelExtensions on Widget {
  Widget animatedPanelX({
    final double closeX = 0.0,
    final bool? isClosed,
    final double? duration,
    final Curve? curve,
  }) =>
      animatedPanel(
        closePos: Offset(closeX, 0),
        isClosed: isClosed,
        curve: curve,
        duration: duration,
      );

  Widget animatedPanelY({
    final double closeY = 0.0,
    final bool? isClosed,
    final double? duration,
    final Curve? curve,
  }) =>
      animatedPanel(
        closePos: Offset(0, closeY),
        isClosed: isClosed,
        curve: curve,
        duration: duration,
      );

  Widget animatedPanel({
    required final Offset closePos,
    final bool? isClosed,
    final double? duration,
    final Curve? curve,
  }) {
    return AnimatedPanel(
      closedX: closePos.dx,
      closedY: closePos.dy,
      isClosed: isClosed ?? false,
      duration: duration ?? .35,
      curve: curve,
      child: this,
    );
  }
}
