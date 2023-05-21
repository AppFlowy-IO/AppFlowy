import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flowy_infra/time/duration.dart';

typedef HoverBuilder = Widget Function(BuildContext context, bool onHover);

class FlowyHover extends StatefulWidget {
  final HoverStyle? style;
  final HoverBuilder? builder;
  final Widget? child;

  final bool Function()? isSelected;
  final void Function(bool)? onHover;
  final MouseCursor? cursor;

  /// Determined whether the [builder] should get called when onEnter/onExit
  /// happened
  ///
  /// [FlowyHover] show hover when [MouseRegion]'s onEnter get called
  /// [FlowyHover] hide hover when [MouseRegion]'s onExit get called
  ///
  final bool Function()? buildWhenOnHover;

  const FlowyHover({
    Key? key,
    this.builder,
    this.child,
    this.style,
    this.isSelected,
    this.onHover,
    this.cursor,
    this.buildWhenOnHover,
  }) : super(key: key);

  @override
  State<FlowyHover> createState() => _FlowyHoverState();
}

class _FlowyHoverState extends State<FlowyHover> {
  bool _onHover = false;

  @override
  void didUpdateWidget(covariant FlowyHover oldWidget) {
    // Reset the _onHover to false when the parent widget get rebuild.
    _onHover = false;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor != null ? widget.cursor! : SystemMouseCursors.click,
      opaque: false,
      onHover: (p) {
        if (_onHover) return;

        if (widget.buildWhenOnHover?.call() ?? true) {
          setState(() => _onHover = true);
          if (widget.onHover != null) {
            widget.onHover!(true);
          }
        }
      },
      onExit: (p) {
        if (_onHover == false) return;

        if (widget.buildWhenOnHover?.call() ?? true) {
          setState(() => _onHover = false);
          if (widget.onHover != null) {
            widget.onHover!(false);
          }
        }
      },
      child: renderWidget(),
    );
  }

  Widget renderWidget() {
    var showHover = _onHover;
    if (!showHover && widget.isSelected != null) {
      showHover = widget.isSelected!();
    }

    final child = widget.child ?? widget.builder!(context, _onHover);
    final style = widget.style ??
        HoverStyle(hoverColor: Theme.of(context).colorScheme.secondary);
    if (showHover) {
      return FlowyHoverContainer(
        style: style,
        child: child,
      );
    } else {
      return Container(color: style.backgroundColor, child: child);
    }
  }
}

class HoverStyle {
  final Color borderColor;
  final double borderWidth;
  final Color? hoverColor;
  final Color? foregroundColorOnHover;
  final BorderRadius borderRadius;
  final EdgeInsets contentMargin;
  final Color backgroundColor;

  const HoverStyle({
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.contentMargin = EdgeInsets.zero,
    this.backgroundColor = Colors.transparent,
    this.hoverColor,
    this.foregroundColorOnHover,
  });
}

class FlowyHoverContainer extends StatelessWidget {
  final HoverStyle style;
  final Widget child;

  const FlowyHoverContainer({
    Key? key,
    required this.child,
    required this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hoverBorder = Border.all(
      color: style.borderColor,
      width: style.borderWidth,
    );

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final iconTheme = theme.iconTheme;
    // override text's theme with foregroundColorOnHover when it is hovered
    final hoverTheme = theme.copyWith(
      textTheme: textTheme.copyWith(
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: style.foregroundColorOnHover ?? theme.colorScheme.onSurface,
        ),
      ),
      iconTheme: iconTheme.copyWith(
        color: style.foregroundColorOnHover ?? theme.colorScheme.onSurface,
      ),
    );

    return Container(
      margin: style.contentMargin,
      decoration: BoxDecoration(
        border: hoverBorder,
        color: style.hoverColor ?? Theme.of(context).colorScheme.secondary,
        borderRadius: style.borderRadius,
      ),
      child: Theme(
        data: hoverTheme,
        child: child,
      ),
    );
  }
}
