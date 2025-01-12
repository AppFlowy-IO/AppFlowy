import 'dart:convert';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/shared/custom_image_cache_manager.dart';
import 'package:appflowy/util/string_extension.dart';
import 'package:appflowy_backend/log.dart';
import 'package:appflowy_backend/protobuf/flowy-user/protobuf.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flowy_infra/uuid.dart';
import 'package:flowy_infra_ui/style_widget/text.dart';
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
    this.maxRetries = 5,
    this.retryDuration = const Duration(seconds: 6),
    this.retryErrorCodes = const {404},
    this.onImageLoaded,
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

  /// Retry error codes.
  final Set<int> retryErrorCodes;

  final void Function(bool isImageInCache)? onImageLoaded;

  @override
  FlowyNetworkImageState createState() => FlowyNetworkImageState();
}

class FlowyNetworkImageState extends State<FlowyNetworkImage> {
  final manager = CustomImageCacheManager();
  final retryCounter = _FlowyNetworkRetryCounter();

  // This is used to clear the retry count when the widget is disposed in case of the url is the same.
  String? retryTag;

  @override
  void initState() {
    super.initState();

    assert(isURL(widget.url));

    if (widget.url.isAppFlowyCloudUrl) {
      assert(
        widget.userProfilePB != null && widget.userProfilePB!.token.isNotEmpty,
      );
    }

    retryTag = retryCounter.add(widget.url);

    manager.getFileFromCache(widget.url).then((file) {
      widget.onImageLoaded?.call(
        file != null &&
            file.file.path.isNotEmpty &&
            file.originalUrl == widget.url,
      );
    });
  }

  @override
  void reassemble() {
    super.reassemble();

    if (retryTag != null) {
      retryCounter.clear(retryTag!);
    }
  }

  @override
  void dispose() {
    if (retryTag != null) {
      retryCounter.clear(retryTag!);
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: retryCounter,
      builder: (context, child) {
        final retryCount = retryCounter.getRetryCount(widget.url);
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
            Log.error(
              'Unable to load image: ${value.toString()} - retryCount: $retryCount',
            );

            // clear the cache and retry
            await manager.removeFile(widget.url);
            _retryLoadImage();
          },
        );
      },
    );
  }

  /// if the error is 404 and the retry count is less than the max retries, it return a loading indicator.
  Widget _errorWidgetBuilder(BuildContext context, String url, Object error) {
    final retryCount = retryCounter.getRetryCount(url);
    if (error is HttpExceptionWithStatus) {
      if (widget.retryErrorCodes.contains(error.statusCode) &&
          retryCount < widget.maxRetries) {
        final fakeDownloadProgress = DownloadProgress(url, null, 0);
        return widget.progressIndicatorBuilder?.call(
              context,
              url,
              fakeDownloadProgress,
            ) ??
            const Center(
              child: _SensitiveContent(),
            );
      }

      if (error.statusCode == 422) {
        // Unprocessable Entity: Used when the server understands the request but cannot process it due to
        //semantic issues (e.g., sensitive keywords).
        return const _SensitiveContent();
      }
    }

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
    final retryCount = retryCounter.getRetryCount(widget.url);
    if (retryCount < widget.maxRetries) {
      Future.delayed(widget.retryDuration, () {
        Log.debug(
          'Retry load image: ${widget.url}, retry count: $retryCount',
        );
        // Increment the retry count for the URL to trigger the image rebuild.
        retryCounter.increment(widget.url);
      });
    }
  }
}

/// This class is used to count the number of retries for a given URL.
class _FlowyNetworkRetryCounter with ChangeNotifier {
  _FlowyNetworkRetryCounter._();

  factory _FlowyNetworkRetryCounter() => _instance;
  static final _instance = _FlowyNetworkRetryCounter._();

  final Map<String, int> _values = <String, int>{};
  Map<String, int> get values => {..._values};

  /// Get the retry count for a given URL.
  int getRetryCount(String url) => _values[url] ?? 0;

  /// Add a new URL to the retry counter. Don't call notifyListeners() here.
  ///
  /// This function will return a tag, use it to clear the retry count.
  /// Because the url may be the same, we need to add a unique tag to the url.
  String add(String url) {
    _values.putIfAbsent(url, () => 0);
    return url + uuid();
  }

  /// Increment the retry count for a given URL.
  void increment(String url) {
    final count = _values[url];
    if (count == null) {
      _values[url] = 1;
    } else {
      _values[url] = count + 1;
    }
    notifyListeners();
  }

  /// Clear the retry count for a given URL.
  void clear(String tag) {
    _values.remove(tag);
  }

  /// Reset the retry counter.
  void reset() {
    _values.clear();
  }
}

class _SensitiveContent extends StatelessWidget {
  const _SensitiveContent();

  @override
  Widget build(BuildContext context) {
    return FlowyText(LocaleKeys.ai_contentPolicyViolation.tr());
  }
}
