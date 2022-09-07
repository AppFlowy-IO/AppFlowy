import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flowy_infra/theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import './flowy_popover_layout.dart';

const _overlayContainerPadding = EdgeInsets.all(12);

class FlowyPopover extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final ShapeBorder? shape;
  final Rect anchorRect;
  final AnchorDirection? anchorDirection;
  final EdgeInsets padding;
  final BoxConstraints? constraints;

  const FlowyPopover({
    Key? key,
    required this.builder,
    required this.anchorRect,
    this.shape,
    this.padding = _overlayContainerPadding,
    this.anchorDirection,
    this.constraints,
  }) : super(key: key);

  @override
  State<FlowyPopover> createState() => _FlowyPopoverState();
}

class _FlowyPopoverState extends State<FlowyPopover> {
  final preRenderKey = GlobalKey();
  Size? size;

  @override
  Widget build(BuildContext context) {
    final theme =
        context.watch<AppTheme?>() ?? AppTheme.fromType(ThemeType.light);
    return Material(
        type: MaterialType.transparency,
        child: CustomSingleChildLayout(
            delegate: PopoverLayoutDelegate(
              anchorRect: widget.anchorRect,
              anchorDirection:
                  widget.anchorDirection ?? AnchorDirection.rightWithTopAligned,
              overlapBehaviour: OverlapBehaviour.stretch,
            ),
            child: Container(
              padding: widget.padding,
              constraints: widget.constraints ??
                  BoxConstraints.loose(const Size(280, 400)),
              decoration: FlowyDecoration.decoration(
                  theme.surface, theme.shadowColor.withOpacity(0.15)),
              key: preRenderKey,
              child: widget.builder(context),
            )));
  }
}
