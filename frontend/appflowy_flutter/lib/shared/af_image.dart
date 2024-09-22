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
      );
    } else if (uploadType == FileUploadTypePB.LocalFile) {
      child = Image.file(
        File(url),
        height: height,
        width: width,
        fit: fit,
      );
    } else {
      child = FlowyNetworkImage(
        url: url,
        userProfilePB: userProfile,
        height: height,
        width: width,
      );
    }

    return child;
  }
}
