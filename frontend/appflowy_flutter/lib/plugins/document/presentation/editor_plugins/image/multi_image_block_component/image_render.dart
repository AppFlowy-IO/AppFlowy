import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/plugins/document/presentation/editor_plugins/image/common.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';
import 'package:flowy_infra/size.dart';

@visibleForTesting
class ImageRender extends StatelessWidget {
  const ImageRender({
    super.key,
    required this.image,
    this.userProfile,
    this.fit = BoxFit.cover,
    this.borderRadius = Corners.s6Border,
  });

  final ImageBlockData image;
  final UserProfilePB? userProfile;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final child = switch (image.type) {
      CustomImageType.internal || CustomImageType.external => FlowyNetworkImage(
          url: image.url,
          userProfilePB: userProfile,
          fit: fit,
        ),
      CustomImageType.local => Image.file(File(image.url), fit: fit),
    };

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(borderRadius: borderRadius),
      child: child,
    );
  }
}
