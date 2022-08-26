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

  FlowyPopover({
    Key? key,
    required this.builder,
    required this.anchorRect,
    this.shape,
    this.padding = _overlayContainerPadding,
    this.anchorDirection,
    this.constraints,
  }) : super(key: key);

  static show(
    BuildContext context, {
    required Widget Function(BuildContext context) builder,
    BuildContext? anchorContext,
    Offset? anchorPosition,
    AnchorDirection? anchorDirection,
    Size? anchorSize,
    Offset? anchorOffset,
    BoxConstraints? constraints,
  }) {
    final offset = anchorOffset ?? Offset.zero;
    Offset targetAnchorPosition = anchorPosition ?? Offset.zero;
    Size targetAnchorSize = anchorSize ?? Size.zero;
    if (anchorContext != null) {
      RenderObject renderObject = anchorContext.findRenderObject()!;
      assert(
        renderObject is RenderBox,
        'Unexpected non-RenderBox render object caught.',
      );
      final renderBox = renderObject as RenderBox;
      targetAnchorPosition = renderBox.localToGlobal(Offset.zero);
      targetAnchorSize = renderBox.size;
    }
    final anchorRect = Rect.fromLTWH(
      targetAnchorPosition.dx + offset.dx,
      targetAnchorPosition.dy + offset.dy,
      targetAnchorSize.width,
      targetAnchorSize.height,
    );

    showDialog(
        barrierColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return FlowyPopover(
              anchorRect: anchorRect,
              anchorDirection: anchorDirection,
              constraints: constraints,
              builder: (BuildContext context) {
                return builder(context);
              });
        });
  }

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
