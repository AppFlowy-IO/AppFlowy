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
    this.maxRetries = 3,
    this.retryDuration = const Duration(seconds: 6),
  });

  /// The URL of the image.
  final String url;

  /// The width of the image.
  final double? width;

  /// The height of the image.
  final double? height;

  /// The fit of the image.
  final BoxFit fit;

  /// The user profile.
  ///
  /// If the userProfilePB is not null, the image will be downloaded with the access token.
  final UserProfilePB? userProfilePB;

  /// The progress indicator builder.
  final ProgressIndicatorBuilder? progressIndicatorBuilder;

  /// The error widget builder.
  final LoadingErrorWidgetBuilder? errorWidgetBuilder;

  /// Retry loading the image if it fails.
  final int maxRetries;

  /// Retry duration
  final Duration retryDuration;

  @override
  FlowyNetworkImageState createState() => FlowyNetworkImageState();
}

class FlowyNetworkImageState extends State<FlowyNetworkImage> {
  final manager = CustomImageCacheManager();

  int retryCount = 0;

  @override
  void initState() {
    super.initState();

    assert(isURL(widget.url));

    if (widget.url.isAppFlowyCloudUrl) {
      assert(
        widget.userProfilePB != null && widget.userProfilePB!.token.isNotEmpty,
      );
    }
  }

  @override
  void reassemble() {
    super.reassemble();

    retryCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      key: ValueKey('${widget.url}_$retryCount'),
      cacheManager: manager,
      httpHeaders: _buildRequestHeader(),
      imageUrl: widget.url,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      progressIndicatorBuilder: widget.progressIndicatorBuilder,
      errorWidget: _errorWidgetBuilder,
      errorListener: (value) async {
        Log.error('Unable to load image: ${value.toString()}');

        await manager.removeFile(widget.url);
        _retryLoadImage();
      },
    );
  }

  /// if the error is 404 and the retry count is less than the max retries, it return a loading indicator.
  Widget _errorWidgetBuilder(BuildContext context, String url, Object error) {
    if (error is HttpExceptionWithStatus &&
        error.statusCode == 404 &&
        retryCount < widget.maxRetries) {
      final fakeDownloadProgress = DownloadProgress(url, null, 0);
      return widget.progressIndicatorBuilder?.call(
            context,
            url,
            fakeDownloadProgress,
          ) ??
          const Center(
            child: CircularProgressIndicator(),
          );
    }

    // Default error widget behavior
    return widget.errorWidgetBuilder?.call(context, url, error) ??
        const SizedBox.shrink();
  }

  Map<String, String> _buildRequestHeader() {
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

  void _retryLoadImage() {
    if (retryCount < widget.maxRetries) {
      Log.debug('Retry load image: ${widget.url}, retry count: $retryCount');

      Future.delayed(widget.retryDuration, () {
        if (mounted) {
          setState(() {
            retryCount++;
          });
        }
      });
    }
  }
}
