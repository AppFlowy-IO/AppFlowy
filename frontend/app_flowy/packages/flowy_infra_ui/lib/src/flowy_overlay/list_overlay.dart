import 'package:flutter/material.dart';

import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
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
    Key? key,
    required this.itemBuilder,
    this.itemCount,
    this.controller,
    this.width = double.infinity,
    this.height = double.infinity,
    this.footer,
  }) : super(key: key);

  final IndexedWidgetBuilder itemBuilder;
  final int? itemCount;
  final ScrollController? controller;
  final double width;
  final double height;
  final ListOverlayFooter? footer;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 6, vertical: 6);
    double totalHeight = height + padding.vertical;
    if (footer != null) {
      totalHeight = totalHeight + footer!.height + footer!.padding.vertical;
    }

    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: FlowyDecoration.decoration(
          Theme.of(context).colorScheme.surface,
          // FIXME: Use `elevation`.
          Colors.black12,
        ),
        constraints: BoxConstraints.tight(Size(width, totalHeight)),
        child: Padding(
          padding: padding,
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemBuilder: itemBuilder,
                itemCount: itemCount,
                controller: controller,
              ),
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
    int? itemCount,
    ScrollController? controller,
    double width = double.infinity,
    double height = double.infinity,
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
        width: width,
        height: height,
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

  static void showWithRect(
    BuildContext context, {
    required BuildContext anchorContext,
    required String identifier,
    required IndexedWidgetBuilder itemBuilder,
    int? itemCount,
    ScrollController? controller,
    double maxWidth = double.infinity,
    double maxHeight = double.infinity,
    required Offset anchorPosition,
    required Size anchorSize,
    AnchorDirection? anchorDirection,
    FlowyOverlayDelegate? delegate,
    OverlapBehaviour? overlapBehaviour,
    FlowyOverlayStyle? style,
  }) {
    FlowyOverlay.of(context).insertWithRect(
      widget: ListOverlay(
        itemBuilder: itemBuilder,
        itemCount: itemCount,
        controller: controller,
        width: maxWidth,
        height: maxHeight,
      ),
      identifier: identifier,
      anchorPosition: anchorPosition,
      anchorSize: anchorSize,
      anchorDirection: anchorDirection,
      delegate: delegate,
      overlapBehaviour: overlapBehaviour,
      style: style,
    );
  }
}
