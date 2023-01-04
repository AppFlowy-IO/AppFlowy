import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import './popover.dart';

class PopoverLayoutDelegate extends SingleChildLayoutDelegate {
  PopoverLink link;
  PopoverDirection direction;
  final Offset offset;
  final EdgeInsets windowPadding;

  PopoverLayoutDelegate({
    required this.link,
    required this.direction,
    required this.offset,
    required this.windowPadding,
  });

  @override
  bool shouldRelayout(PopoverLayoutDelegate oldDelegate) {
    if (direction != oldDelegate.direction) {
      return true;
    }

    if (link != oldDelegate.link) {
      return true;
    }

    if (link.leaderOffset != oldDelegate.link.leaderOffset) {
      return true;
    }

    if (link.leaderSize != oldDelegate.link.leaderSize) {
      return true;
    }

    return false;
  }

  @override
  Size getSize(BoxConstraints constraints) {
    return Size(
      constraints.maxWidth - windowPadding.left - windowPadding.right,
      constraints.maxHeight - windowPadding.top - windowPadding.bottom,
    );
  }

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: constraints.maxWidth - windowPadding.left - windowPadding.right,
      maxHeight:
          constraints.maxHeight - windowPadding.top - windowPadding.bottom,
    );
    // assert(link.leaderSize != null);
    // // if (link.leaderSize == null) {
    // //   return constraints.loosen();
    // // }
    // final anchorRect = Rect.fromLTWH(
    //   link.leaderOffset!.dx,
    //   link.leaderOffset!.dy,
    //   link.leaderSize!.width,
    //   link.leaderSize!.height,
    // );
    // BoxConstraints childConstraints;
    // switch (direction) {
    //   case PopoverDirection.topLeft:
    //     childConstraints = BoxConstraints.loose(Size(
    //       anchorRect.left,
    //       anchorRect.top,
    //     ));
    //     break;
    //   case PopoverDirection.topRight:
    //     childConstraints = BoxConstraints.loose(Size(
    //       constraints.maxWidth - anchorRect.right,
    //       anchorRect.top,
    //     ));
    //     break;
    //   case PopoverDirection.bottomLeft:
    //     childConstraints = BoxConstraints.loose(Size(
    //       anchorRect.left,
    //       constraints.maxHeight - anchorRect.bottom,
    //     ));
    //     break;
    //   case PopoverDirection.bottomRight:
    //     childConstraints = BoxConstraints.loose(Size(
    //       constraints.maxWidth - anchorRect.right,
    //       constraints.maxHeight - anchorRect.bottom,
    //     ));
    //     break;
    //   case PopoverDirection.center:
    //     childConstraints = BoxConstraints.loose(Size(
    //       constraints.maxWidth,
    //       constraints.maxHeight,
    //     ));
    //     break;
    //   case PopoverDirection.topWithLeftAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       constraints.maxWidth - anchorRect.left,
    //       anchorRect.top,
    //     ));
    //     break;
    //   case PopoverDirection.topWithCenterAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       constraints.maxWidth,
    //       anchorRect.top,
    //     ));
    //     break;
    //   case PopoverDirection.topWithRightAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       anchorRect.right,
    //       anchorRect.top,
    //     ));
    //     break;
    //   case PopoverDirection.rightWithTopAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       constraints.maxWidth - anchorRect.right,
    //       constraints.maxHeight - anchorRect.top,
    //     ));
    //     break;
    //   case PopoverDirection.rightWithCenterAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       constraints.maxWidth - anchorRect.right,
    //       constraints.maxHeight,
    //     ));
    //     break;
    //   case PopoverDirection.rightWithBottomAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       constraints.maxWidth - anchorRect.right,
    //       anchorRect.bottom,
    //     ));
    //     break;
    //   case PopoverDirection.bottomWithLeftAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       anchorRect.left,
    //       constraints.maxHeight - anchorRect.bottom,
    //     ));
    //     break;
    //   case PopoverDirection.bottomWithCenterAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       constraints.maxWidth,
    //       constraints.maxHeight - anchorRect.bottom,
    //     ));
    //     break;
    //   case PopoverDirection.bottomWithRightAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       anchorRect.right,
    //       constraints.maxHeight - anchorRect.bottom,
    //     ));
    //     break;
    //   case PopoverDirection.leftWithTopAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       anchorRect.left,
    //       constraints.maxHeight - anchorRect.top,
    //     ));
    //     break;
    //   case PopoverDirection.leftWithCenterAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       anchorRect.left,
    //       constraints.maxHeight,
    //     ));
    //     break;
    //   case PopoverDirection.leftWithBottomAligned:
    //     childConstraints = BoxConstraints.loose(Size(
    //       anchorRect.left,
    //       anchorRect.bottom,
    //     ));
    //     break;
    //   case PopoverDirection.custom:
    //     childConstraints = constraints.loosen();
    //     break;
    //   default:
    //     throw UnimplementedError();
    // }
    // return childConstraints;
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    if (link.leaderSize == null) {
      return Offset.zero;
    }
    final anchorRect = Rect.fromLTWH(
      link.leaderOffset!.dx + offset.dx,
      link.leaderOffset!.dy + offset.dy,
      link.leaderSize!.width,
      link.leaderSize!.height,
    );
    Offset position;
    switch (direction) {
      case PopoverDirection.topLeft:
        position = Offset(
          anchorRect.left - childSize.width,
          anchorRect.top - childSize.height,
        );
        break;
      case PopoverDirection.topRight:
        position = Offset(
          anchorRect.right,
          anchorRect.top - childSize.height,
        );
        break;
      case PopoverDirection.bottomLeft:
        position = Offset(
          anchorRect.left - childSize.width,
          anchorRect.bottom,
        );
        break;
      case PopoverDirection.bottomRight:
        position = Offset(
          anchorRect.right,
          anchorRect.bottom,
        );
        break;
      case PopoverDirection.center:
        position = anchorRect.center;
        break;
      case PopoverDirection.topWithLeftAligned:
        position = Offset(
          anchorRect.left,
          anchorRect.top - childSize.height,
        );
        break;
      case PopoverDirection.topWithCenterAligned:
        position = Offset(
          anchorRect.left + anchorRect.width / 2.0 - childSize.width / 2.0,
          anchorRect.top - childSize.height,
        );
        break;
      case PopoverDirection.topWithRightAligned:
        position = Offset(
          anchorRect.right - childSize.width,
          anchorRect.top - childSize.height,
        );
        break;
      case PopoverDirection.rightWithTopAligned:
        position = Offset(anchorRect.right, anchorRect.top);
        break;
      case PopoverDirection.rightWithCenterAligned:
        position = Offset(
          anchorRect.right,
          anchorRect.top + anchorRect.height / 2.0 - childSize.height / 2.0,
        );
        break;
      case PopoverDirection.rightWithBottomAligned:
        position = Offset(
          anchorRect.right,
          anchorRect.bottom - childSize.height,
        );
        break;
      case PopoverDirection.bottomWithLeftAligned:
        position = Offset(
          anchorRect.left,
          anchorRect.bottom,
        );
        break;
      case PopoverDirection.bottomWithCenterAligned:
        position = Offset(
          anchorRect.left + anchorRect.width / 2.0 - childSize.width / 2.0,
          anchorRect.bottom,
        );
        break;
      case PopoverDirection.bottomWithRightAligned:
        position = Offset(
          anchorRect.right - childSize.width,
          anchorRect.bottom,
        );
        break;
      case PopoverDirection.leftWithTopAligned:
        position = Offset(
          anchorRect.left - childSize.width,
          anchorRect.top,
        );
        break;
      case PopoverDirection.leftWithCenterAligned:
        position = Offset(
          anchorRect.left - childSize.width,
          anchorRect.top + anchorRect.height / 2.0 - childSize.height / 2.0,
        );
        break;
      case PopoverDirection.leftWithBottomAligned:
        position = Offset(
          anchorRect.left - childSize.width,
          anchorRect.bottom - childSize.height,
        );
        break;
      default:
        throw UnimplementedError();
    }
    return Offset(
      math.max(
          windowPadding.left,
          math.min(
              windowPadding.left + size.width - childSize.width, position.dx)),
      math.max(
          windowPadding.top,
          math.min(
              windowPadding.top + size.height - childSize.height, position.dy)),
    );
  }
}

class PopoverTarget extends SingleChildRenderObjectWidget {
  final PopoverLink link;
  const PopoverTarget({
    super.key,
    super.child,
    required this.link,
  });

  @override
  PopoverTargetRenderBox createRenderObject(BuildContext context) {
    return PopoverTargetRenderBox(
      link: link,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, PopoverTargetRenderBox renderObject) {
    renderObject.link = link;
  }
}

class PopoverTargetRenderBox extends RenderProxyBox {
  PopoverLink link;
  PopoverTargetRenderBox({required this.link, RenderBox? child}) : super(child);

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performLayout() {
    super.performLayout();
    link.leaderSize = size;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    link.leaderOffset = localToGlobal(Offset.zero);
    super.paint(context, offset);
  }

  @override
  void detach() {
    super.detach();
    link.leaderOffset = null;
    link.leaderSize = null;
  }

  @override
  void attach(covariant PipelineOwner owner) {
    super.attach(owner);
    if (hasSize) {
      // The leaderSize was set after [performLayout], but was
      // set to null when [detach] get called.
      //
      // set the leaderSize when attach get called
      link.leaderSize = size;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PopoverLink>('link', link));
  }
}

class PopoverLink {
  Offset? leaderOffset;
  Size? leaderSize;
}
