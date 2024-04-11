import 'package:flutter/material.dart';

class AnimatedPanel extends StatefulWidget {
  const AnimatedPanel({
    super.key,
    this.isClosed = false,
    this.closedX = 0.0,
    this.closedY = 0.0,
    this.duration = 0.0,
    this.curve,
    this.child,
  });

  final bool isClosed;
  final double closedX;
  final double closedY;
  final double duration;
  final Curve? curve;
  final Widget? child;

  @override
  AnimatedPanelState createState() => AnimatedPanelState();
}

class AnimatedPanelState extends State<AnimatedPanel> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    final Offset closePos = Offset(widget.closedX, widget.closedY);
    final double duration = _isHidden && widget.isClosed ? 0 : widget.duration;
    return TweenAnimationBuilder(
      curve: widget.curve ?? Curves.easeOut,
      tween: Tween<Offset>(
        begin: !widget.isClosed ? Offset.zero : closePos,
        end: !widget.isClosed ? Offset.zero : closePos,
      ),
      duration: Duration(milliseconds: (duration * 1000).round()),
      builder: (_, Offset value, Widget? c) {
        _isHidden =
            widget.isClosed && value == Offset(widget.closedX, widget.closedY);
        return _isHidden
            ? const SizedBox.shrink()
            : Transform.translate(offset: value, child: c);
      },
      child: widget.child,
    );
  }
}

extension AnimatedPanelExtensions on Widget {
  Widget animatedPanelX({
    double closeX = 0.0,
    bool? isClosed,
    double? duration,
    Curve? curve,
  }) =>
      animatedPanel(
        closePos: Offset(closeX, 0),
        isClosed: isClosed,
        curve: curve,
        duration: duration,
      );

  Widget animatedPanelY({
    double closeY = 0.0,
    bool? isClosed,
    double? duration,
    Curve? curve,
  }) =>
      animatedPanel(
        closePos: Offset(0, closeY),
        isClosed: isClosed,
        curve: curve,
        duration: duration,
      );

  Widget animatedPanel({
    required Offset closePos,
    bool? isClosed,
    double? duration,
    Curve? curve,
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
