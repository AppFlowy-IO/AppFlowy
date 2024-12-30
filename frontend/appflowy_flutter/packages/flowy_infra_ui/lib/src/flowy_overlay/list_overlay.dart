import 'dart:math';

import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';

class ListOverlayFooter {
  Widget widget;
  double height;
  EdgeInsets padding;
  ListOverlayFooter({
    required this.widget,
    required this.height,
    this.padding = EdgeInsets.zero,
  });
}

class ListOverlay extends StatelessWidget {
  const ListOverlay({
    super.key,
    required this.itemBuilder,
    this.itemCount = 0,
    this.controller,
    this.constraints = const BoxConstraints(),
    this.footer,
  });

  final IndexedWidgetBuilder itemBuilder;
  final int itemCount;
  final ScrollController? controller;
  final BoxConstraints constraints;
  final ListOverlayFooter? footer;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 6, vertical: 6);
    double totalHeight = constraints.minHeight + padding.vertical;
    if (footer != null) {
      totalHeight = totalHeight + footer!.height + footer!.padding.vertical;
    }

    final innerConstraints = BoxConstraints(
      minHeight: totalHeight,
      maxHeight: max(constraints.maxHeight, totalHeight),
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
    );

    List<Widget> children = [];
    for (var i = 0; i < itemCount; i++) {
      children.add(itemBuilder(context, i));
    }

    return OverlayContainer(
      constraints: innerConstraints,
      padding: padding,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              ...children,
              if (footer != null)
                Padding(
                  padding: footer!.padding,
                  child: footer!.widget,
                ),
            ],
          ),
        ),
      ),
    );
  }

  static void showWithAnchor(
    BuildContext context, {
    required String identifier,
    required IndexedWidgetBuilder itemBuilder,
    int itemCount = 0,
    ScrollController? controller,
    BoxConstraints constraints = const BoxConstraints(),
    required BuildContext anchorContext,
    AnchorDirection? anchorDirection,
    FlowyOverlayDelegate? delegate,
    OverlapBehaviour? overlapBehaviour,
    FlowyOverlayStyle? style,
    Offset? anchorOffset,
    ListOverlayFooter? footer,
  }) {
    FlowyOverlay.of(context).insertWithAnchor(
      widget: ListOverlay(
        itemBuilder: itemBuilder,
        itemCount: itemCount,
        controller: controller,
        constraints: constraints,
        footer: footer,
      ),
      identifier: identifier,
      anchorContext: anchorContext,
      anchorDirection: anchorDirection,
      delegate: delegate,
      overlapBehaviour: overlapBehaviour,
      anchorOffset: anchorOffset,
      style: style,
    );
  }
}

const overlayContainerPadding = EdgeInsets.all(12);

class OverlayContainer extends StatelessWidget {
  final Widget child;
  final BoxConstraints? constraints;
  final EdgeInsets padding;
  const OverlayContainer({
    required this.child,
    this.constraints,
    this.padding = overlayContainerPadding,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: padding,
        decoration: FlowyDecoration.decoration(
          Theme.of(context).colorScheme.surface,
          Theme.of(context).colorScheme.shadow.withOpacity(0.15),
        ),
        constraints: constraints,
        child: child,
      ),
    );
  }
}
