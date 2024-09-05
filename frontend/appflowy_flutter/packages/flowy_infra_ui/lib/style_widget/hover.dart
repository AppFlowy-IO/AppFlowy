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
      child: _Render(
        isHovering: _onHover || (widget.isSelected?.call() ?? false),
        style: widget.style,
        builder: widget.builder,
        child: widget.child,
      ),
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
}

class _Render extends StatelessWidget {
  const _Render({
    this.child,
    this.builder,
    required this.isHovering,
    this.style,
  });

  final Widget? child;
  final HoverBuilder? builder;
  final bool isHovering;
  final HoverStyle? style;

  @override
  Widget build(BuildContext context) {
    final childWidget = child ?? builder!(context, isHovering);
    final hoverStyle = style ??
        HoverStyle(hoverColor: Theme.of(context).colorScheme.secondary);

    return FlowyHoverContainer(
      style: hoverStyle,
      applyStyle: isHovering,
      child: childWidget,
    );
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
  final bool applyStyle;

  const FlowyHoverContainer({
    super.key,
    required this.child,
    required this.style,
    this.applyStyle = false,
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
        color: applyStyle
            ? style.hoverColor ?? Theme.of(context).colorScheme.secondary
            : style.backgroundColor,
        borderRadius: style.borderRadius,
      ),
      child: Theme(
        data: hoverTheme,
        child: child,
      ),
    );
  }
}
