import 'package:flutter/widgets.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';

/// Abstract class for providing images to the [InteractiveImageViewer].
///
abstract class AFImageProvider {
  const AFImageProvider({this.onDeleteImage});

  /// Provide this callback if you want it to be possible to
  /// delete the Image through the [InteractiveImageViewer].
  ///
  final Function(int index)? onDeleteImage;

  int get imageCount;
  int get initialIndex;

  ImageBlockData getImage(int index);
  Widget renderImage(
    BuildContext context,
    int index, [
    UserProfilePB? userProfile,
  ]);
}

class AFBlockImageProvider implements AFImageProvider {
  const AFBlockImageProvider({
    required this.images,
    this.initialIndex = 0,
    required this.onDeleteImage,
  });

  final List<ImageBlockData> images;

  @override
  final Function(int) onDeleteImage;

  @override
  final int initialIndex;

  @override
  int get imageCount => images.length;

  @override
  ImageBlockData getImage(int index) => images[index];

  @override
  Widget renderImage(
    BuildContext context,
    int index, [
    UserProfilePB? userProfile,
  ]) {
    final image = getImage(index);

    if (image.type == CustomImageType.local) {
      return Image(image: image.toImageProvider());
    }

    return FlowyNetworkImage(
      url: image.url,
      userProfilePB: userProfile,
      fit: BoxFit.contain,
    );
  }
}
