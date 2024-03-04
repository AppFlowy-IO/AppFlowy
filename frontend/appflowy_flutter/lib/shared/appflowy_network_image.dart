import 'dart:convert';

import 'package:appflowy/shared/custom_image_cache_manager.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:string_validator/string_validator.dart';

/// This widget handles the downloading and caching of either internal or network images.
///
/// It will append the access token to the URL if the URL is internal.
class FlowyNetworkImage extends StatelessWidget {
  const FlowyNetworkImage({
    super.key,
    this.userProfilePB,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.progressIndicatorBuilder,
    this.errorWidgetBuilder,
    required this.url,
  });

  final UserProfilePB? userProfilePB;
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final LoadingErrorWidgetBuilder? errorWidgetBuilder;

  @override
  Widget build(BuildContext context) {
    assert(isURL(url));

    if (url.isAppFlowyCloudUrl) {
      assert(userProfilePB != null && userProfilePB!.token.isNotEmpty);
    }

    final manager = CustomImageCacheManager();

    return CachedNetworkImage(
      cacheManager: manager,
      httpHeaders: _header(),
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      progressIndicatorBuilder: progressIndicatorBuilder,
      errorWidget: (context, url, error) =>
          errorWidgetBuilder?.call(context, url, error) ??
          const SizedBox.shrink(),
      errorListener: (value) {
        // try to clear the image cache.
        manager.removeFile(url);

        Log.error(value.toString());
      },
    );
  }

  Map<String, String> _header() {
    final header = <String, String>{};
    final token = userProfilePB?.token;
    if (token != null) {
      try {
        final decodedToken = jsonDecode(token);
        header['Authorization'] = 'Bearer ${decodedToken['access_token']}';
      } catch (e) {
        Log.error('unable to decode token: $e');
      }
    }
    return header;
  }
}
