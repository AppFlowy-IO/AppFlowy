import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PopoverCompositedTransformFollower extends CompositedTransformFollower {
  const PopoverCompositedTransformFollower({
    super.key,
    required super.link,
    super.showWhenUnlinked = true,
    super.offset = Offset.zero,
    super.targetAnchor = Alignment.topLeft,
    super.followerAnchor = Alignment.topLeft,
    super.child,
  });

  @override
  PopoverRenderFollowerLayer createRenderObject(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return PopoverRenderFollowerLayer(
      screenSize: screenSize,
      link: link,
      showWhenUnlinked: showWhenUnlinked,
      offset: offset,
      leaderAnchor: targetAnchor,
      followerAnchor: followerAnchor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    PopoverRenderFollowerLayer renderObject,
  ) {
    final screenSize = MediaQuery.of(context).size;
    renderObject
      ..screenSize = screenSize
      ..link = link
      ..showWhenUnlinked = showWhenUnlinked
      ..offset = offset
      ..leaderAnchor = targetAnchor
      ..followerAnchor = followerAnchor;
  }
}

class PopoverRenderFollowerLayer extends RenderFollowerLayer {
  PopoverRenderFollowerLayer({
    required super.link,
    super.showWhenUnlinked = true,
    super.offset = Offset.zero,
    super.leaderAnchor = Alignment.topLeft,
    super.followerAnchor = Alignment.topLeft,
    super.child,
    required this.screenSize,
  });

  Size screenSize;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    if (link.leader == null) {
      return;
    }

    if (link.leader!.offset.dx + link.leaderSize!.width + size.width >
        screenSize.width) {
      debugPrint('over flow');
    }
    debugPrint(
      'right: ${link.leader!.offset.dx + link.leaderSize!.width + size.width}, screen with: ${screenSize.width}',
    );
  }
}

class EdgeFollowerLayer extends FollowerLayer {
  EdgeFollowerLayer({
    required super.link,
    super.showWhenUnlinked = true,
    super.unlinkedOffset = Offset.zero,
    super.linkedOffset = Offset.zero,
  });
}
