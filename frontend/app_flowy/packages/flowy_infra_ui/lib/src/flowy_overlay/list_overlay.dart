import 'package:flowy_infra_ui/flowy_infra_ui.dart';
import 'package:flutter/material.dart';
import 'package:flowy_infra/theme.dart';
import 'package:flowy_infra_ui/style_widget/decoration.dart';
import 'package:provider/provider.dart';

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

    return OverlayContainer(
      constraints: BoxConstraints.tight(Size(width, totalHeight)),
      padding: padding,
      child: SingleChildScrollView(
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme =
        context.watch<AppTheme?>() ?? AppTheme.fromType(ThemeType.light);
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: padding,
        decoration: FlowyDecoration.decoration(
            theme.surface, theme.shadowColor.withOpacity(0.15)),
        constraints: constraints,
        child: child,
      ),
    );
  }
}
