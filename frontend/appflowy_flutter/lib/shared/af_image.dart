import 'dart:io';

import 'package:flutter/material.dart';

import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy_backend/protobuf/flowy-database2/file_entities.pbenum.dart';
import 'package:appflowy_backend/protobuf/flowy-user/user_profile.pb.dart';

class AFImage extends StatelessWidget {
  const AFImage({
    super.key,
    required this.url,
    required this.uploadType,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.userProfile,
    this.borderRadius,
  }) : assert(
          uploadType != FileUploadTypePB.CloudFile || userProfile != null,
          'userProfile must be provided for accessing files from AF Cloud',
        );

  final String url;
  final FileUploadTypePB uploadType;
  final double? height;
  final double? width;
  final BoxFit fit;
  final UserProfilePB? userProfile;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (uploadType == FileUploadTypePB.CloudFile && userProfile == null) {
      return const SizedBox.shrink();
    }

    Widget child;
    if (uploadType == FileUploadTypePB.NetworkFile) {
      child = Image.network(
        url,
        height: height,
        width: width,
        fit: fit,
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        },
      );
    } else if (uploadType == FileUploadTypePB.LocalFile) {
      child = Image.file(
        File(url),
        height: height,
        width: width,
        fit: fit,
        isAntiAlias: true,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        },
      );
    } else {
      child = FlowyNetworkImage(
        url: url,
        userProfilePB: userProfile,
        height: height,
        width: width,
        errorWidgetBuilder: (context, url, error) {
          return const SizedBox.shrink();
        },
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        borderRadius: borderRadius!,
        child: child,
      );
    }

    return child;
  }
}
