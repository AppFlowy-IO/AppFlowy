import 'dart:developer';
import 'dart:io';

import 'package:flowy_svg/flowy_svg.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import 'custom_image_cache_manager.dart';

class FlowyNetworkSvg extends StatefulWidget {
  FlowyNetworkSvg(
    this.url, {
    Key? key,
    this.cacheKey,
    this.placeholder,
    this.errorWidget,
    this.width,
    this.height,
    this.headers,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.matchTextDirection = false,
    this.allowDrawingOutsideViewBox = false,
    this.semanticsLabel,
    this.excludeFromSemantics = false,
    this.theme = const SvgTheme(),
    this.fadeDuration = Duration.zero,
    this.colorFilter,
    this.placeholderBuilder,
    BaseCacheManager? cacheManager,
  })  : cacheManager = cacheManager ?? CustomImageCacheManager(),
        super(key: key ?? ValueKey(url));

  final String url;
  final String? cacheKey;
  final Widget? placeholder;
  final Widget? errorWidget;
  final double? width;
  final double? height;
  final ColorFilter? colorFilter;
  final Map<String, String>? headers;
  final BoxFit fit;
  final AlignmentGeometry alignment;
  final bool matchTextDirection;
  final bool allowDrawingOutsideViewBox;
  final String? semanticsLabel;
  final bool excludeFromSemantics;
  final SvgTheme theme;
  final Duration fadeDuration;
  final WidgetBuilder? placeholderBuilder;
  final BaseCacheManager cacheManager;

  @override
  State<FlowyNetworkSvg> createState() => _FlowyNetworkSvgState();

  static Future<void> preCache(
    String imageUrl, {
    String? cacheKey,
    BaseCacheManager? cacheManager,
  }) {
    final key = cacheKey ?? _generateKeyFromUrl(imageUrl);
    cacheManager ??= DefaultCacheManager();
    return cacheManager.downloadFile(key);
  }

  static Future<void> clearCacheForUrl(
    String imageUrl, {
    String? cacheKey,
    BaseCacheManager? cacheManager,
  }) {
    final key = cacheKey ?? _generateKeyFromUrl(imageUrl);
    cacheManager ??= DefaultCacheManager();
    return cacheManager.removeFile(key);
  }

  static Future<void> clearCache({BaseCacheManager? cacheManager}) {
    cacheManager ??= DefaultCacheManager();
    return cacheManager.emptyCache();
  }

  static String _generateKeyFromUrl(String url) => url.split('?').first;
}

class _FlowyNetworkSvgState extends State<FlowyNetworkSvg>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isError = false;
  File? _imageFile;
  late String _cacheKey;

  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _cacheKey =
        widget.cacheKey ?? FlowyNetworkSvg._generateKeyFromUrl(widget.url);
    _controller = AnimationController(
      vsync: this,
      duration: widget.fadeDuration,
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      _setToLoadingAfter15MsIfNeeded();

      var file = (await widget.cacheManager.getFileFromMemory(_cacheKey))?.file;

      file ??= await widget.cacheManager.getSingleFile(
        widget.url,
        key: _cacheKey,
        headers: widget.headers ?? {},
      );

      _imageFile = file;
      _isLoading = false;

      _setState();

      await _controller.forward();
    } catch (e) {
      log('CachedNetworkSVGImage: $e');

      _isError = true;
      _isLoading = false;

      _setState();
    }
  }

  void _setToLoadingAfter15MsIfNeeded() => Future.delayed(
        const Duration(milliseconds: 15),
        () {
          if (!_isLoading && _imageFile == null && !_isError) {
            _isLoading = true;
            _setState();
          }
        },
      );

  void _setState() => mounted ? setState(() {}) : null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _buildImage(),
    );
  }

  Widget _buildImage() {
    if (_isLoading) return _buildPlaceholderWidget();

    if (_isError) return _buildErrorWidget();

    return FadeTransition(
      opacity: _animation,
      child: _buildSVGImage(),
    );
  }

  Widget _buildPlaceholderWidget() =>
      Center(child: widget.placeholder ?? const SizedBox());

  Widget _buildErrorWidget() =>
      Center(child: widget.errorWidget ?? const SizedBox());

  Widget _buildSVGImage() {
    if (_imageFile == null) return const SizedBox();

    return SvgPicture.file(
      _imageFile!,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      alignment: widget.alignment,
      matchTextDirection: widget.matchTextDirection,
      allowDrawingOutsideViewBox: widget.allowDrawingOutsideViewBox,
      colorFilter: widget.colorFilter,
      semanticsLabel: widget.semanticsLabel,
      excludeFromSemantics: widget.excludeFromSemantics,
      placeholderBuilder: widget.placeholderBuilder,
      theme: widget.theme,
    );
  }
}
