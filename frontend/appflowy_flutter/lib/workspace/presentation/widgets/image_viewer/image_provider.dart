import 'package:flutter/widgets.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/image/custom_image_block_component/custom_image_block_component.dart';

/// Abstract class for providing images to the [InteractiveImageViewer].
///
abstract class AFImageProvider {
  int get imageCount;
  int get initialIndex;

  ImageBlockData getImage(int index);
  Widget renderImage(BuildContext context, int index);
}

class AFBlockImageProvider implements AFImageProvider {
  const AFBlockImageProvider({required this.images, this.initialIndex = 0});

  final List<ImageBlockData> images;

  @override
  final int initialIndex;

  @override
  int get imageCount => images.length;

  @override
  ImageBlockData getImage(int index) => images[index];

  @override
  Widget renderImage(BuildContext context, int index) =>
      Image(image: getImage(index).toImageProvider());
}
