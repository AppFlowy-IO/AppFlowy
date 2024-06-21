import 'package:flutter/material.dart';

typedef HoverBuilder = Widget Function(BuildContext context, bool onHover);

class FlowyHover extends StatefulWidget {
  final HoverStyle? style;
  final HoverBuilder? builder;
  final Widget? child;

  final bool Function()? isSelected;
  final void Function(bool)? onHover;
  final MouseCursor? cursor;

  /// Reset the hover state when the parent widget get rebuild.
  /// Default to true.
  final bool resetHoverOnRebuild;

  /// Determined whether the [builder] should get called when onEnter/onExit
  /// happened
  ///
  /// [FlowyHover] show hover when [MouseRegion]'s onEnter get called
  /// [FlowyHover] hide hover when [MouseRegion]'s onExit get called
  ///
  final bool Function()? buildWhenOnHover;

  const FlowyHover({
    super.key,
    this.builder,
    this.child,
    this.style,
    this.isSelected,
    this.onHover,
    this.cursor,
    this.resetHoverOnRebuild = true,
    this.buildWhenOnHover,
  });

  @override
  State<FlowyHover> createState() => _FlowyHoverState();
}

class _FlowyHoverState extends State<FlowyHover> {
  bool _onHover = false;

  @override
  void didUpdateWidget(covariant FlowyHover oldWidget) {
    if (widget.resetHoverOnRebuild) {
      // Reset the _onHover to false when the parent widget get rebuild.
      _onHover = false;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor != null ? widget.cursor! : SystemMouseCursors.click,
      opaque: false,
      onHover: (p) {
        if (_onHover) return;
        _setOnHover(true);
      },
      onEnter: (p) {
        if (_onHover) return;
        _setOnHover(true);
      },
      onExit: (p) {
        if (!_onHover) return;
        _setOnHover(false);
      },
      child: renderWidget(),
    );
  }

  void _setOnHover(bool isHovering) {
    if (widget.buildWhenOnHover?.call() ?? true) {
      setState(() => _onHover = isHovering);
      if (widget.onHover != null) {
        widget.onHover!(isHovering);
      }
    }
  }

  Widget renderWidget() {
    bool showHover = _onHover;
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
      return Container(
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: style.borderRadius,
        ),
        child: child,
      );
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

  const HoverStyle.transparent({
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
    this.contentMargin = EdgeInsets.zero,
    this.backgroundColor = Colors.transparent,
    this.foregroundColorOnHover,
  }) : hoverColor = Colors.transparent;
}

class FlowyHoverContainer extends StatelessWidget {
  final HoverStyle style;
  final Widget child;

  const FlowyHoverContainer({
    super.key,
    required this.child,
    required this.style,
  });

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
