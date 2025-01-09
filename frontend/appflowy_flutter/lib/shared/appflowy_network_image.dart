import 'dart:convert';

import 'package:appflowy/shared/custom_image_cache_manager.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:string_validator/string_validator.dart';

/// This widget handles the downloading and caching of either internal or network images.
/// It will append the access token to the URL if the URL is internal.
class FlowyNetworkImage extends StatefulWidget {
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
  FlowyNetworkImageState createState() => FlowyNetworkImageState();
}

class FlowyNetworkImageState extends State<FlowyNetworkImage> {
  late final CustomImageCacheManager manager;
  final int maxRetries = 3;
  int retryCount = 0;

  @override
  void initState() {
    super.initState();
    manager = CustomImageCacheManager();
  }

  Future<void> retryLoadImage() async {
    if (retryCount < maxRetries) {
      retryCount++;

      Log.debug("Retry load image: ${widget.url}");
      await Future.delayed(const Duration(seconds: 6)); 
      if (mounted) {
        setState(() {}); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(isURL(widget.url));

    if (widget.url.isAppFlowyCloudUrl) {
      assert(widget.userProfilePB != null &&
          widget.userProfilePB!.token.isNotEmpty,);
    }

    return CachedNetworkImage(
      cacheManager: manager,
      httpHeaders: _header(),
      imageUrl: widget.url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      progressIndicatorBuilder: widget.progressIndicatorBuilder,
      errorWidget: (context, url, error) {
        if (error is HttpExceptionWithStatus && error.statusCode == 404) {
          if (retryCount < maxRetries) {
            retryLoadImage();
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        }

        // Default error widget behavior
        return widget.errorWidgetBuilder?.call(context, url, error) ??
            const SizedBox.shrink();
      },
      errorListener: (value) async {
        await manager.removeFile(widget.url);
        Log.error(value.toString());
      },
    );
  }

  Map<String, String> _header() {
    final header = <String, String>{};
    final token = widget.userProfilePB?.token;
    if (token != null) {
      try {
        final decodedToken = jsonDecode(token);
        header['Authorization'] = 'Bearer ${decodedToken['access_token']}';
      } catch (e) {
        Log.error('Unable to decode token: $e');
      }
    }
    return header;
  }

}