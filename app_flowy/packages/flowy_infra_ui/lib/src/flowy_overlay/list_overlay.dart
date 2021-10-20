import 'package:flowy_infra_ui/flowy_infra_ui_web.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:flutter/material.dart';

class ListOverlay extends StatelessWidget {
  const ListOverlay({
    Key? key,
    required this.itemBuilder,
    this.itemCount,
    this.controller,
    this.maxWidth = double.infinity,
    this.maxHeight = double.infinity,
  }) : super(key: key);

  final IndexedWidgetBuilder itemBuilder;
  final int? itemCount;
  final ScrollController? controller;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        constraints: BoxConstraints.tight(Size(maxWidth, maxHeight)),
        decoration: FlowyDecoration.decoration(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: ListView.builder(
            shrinkWrap: true,
            itemBuilder: itemBuilder,
            itemCount: itemCount,
            controller: controller,
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
    double maxWidth = double.infinity,
    double maxHeight = double.infinity,
    required BuildContext anchorContext,
    AnchorDirection? anchorDirection,
    FlowyOverlayDelegate? delegate,
    OverlapBehaviour? overlapBehaviour,
    FlowyOverlayStyle? style,
  }) {
    FlowyOverlay.of(context).insertWithAnchor(
      widget: ListOverlay(
        itemBuilder: itemBuilder,
        itemCount: itemCount,
        controller: controller,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      ),
      identifier: identifier,
      anchorContext: anchorContext,
      anchorDirection: anchorDirection,
      delegate: delegate,
      overlapBehaviour: overlapBehaviour,
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
        maxWidth: maxWidth,
        maxHeight: maxHeight,
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
