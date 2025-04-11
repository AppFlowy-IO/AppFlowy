import 'dart:convert';
import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/appflowy_network_svg.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:favicon/favicon.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_link_previewer/flutter_link_previewer.dart' hide Size;

class LinkParser {
  static final LinkInfoCache _cache = LinkInfoCache();
  final Set<ValueChanged<LinkInfo>> _listeners = <ValueChanged<LinkInfo>>{};

  Future<void> start(String url) async {
    final data = await _cache.get(url);
    if (data != null) {
      refreshLinkInfo(data);
    }
    await _getLinkInfo(url);
  }

  Future<LinkInfo?> _getLinkInfo(String url) async {
    try {
      final previewData = await getPreviewData(url);
      final favicon = await FaviconFinder.getBest(url);
      final linkInfo = LinkInfo(
        siteName: previewData.title,
        description: previewData.description,
        imageUrl: previewData.image?.url,
        faviconUrl: favicon?.url,
      );
      if (!linkInfo.isEmpty()) await _cache.set(url, linkInfo);
      refreshLinkInfo(linkInfo);
      return linkInfo;
    } catch (e, s) {
      Log.error('get link info error: ', e, s);
      refreshLinkInfo(LinkInfo());
      return null;
    }
  }

  void refreshLinkInfo(LinkInfo info) {
    for (final listener in _listeners) {
      listener(info);
    }
  }

  void addLinkInfoListener(ValueChanged<LinkInfo> listener) {
    _listeners.add(listener);
  }

  void dispose() {
    _listeners.clear();
  }
}

class LinkInfo {
  factory LinkInfo.fromJson(Map<String, dynamic> json) => LinkInfo(
        siteName: json['siteName'],
        description: json['description'],
        imageUrl: json['imageUrl'],
        faviconUrl: json['faviconUrl'],
      );

  LinkInfo({
    this.siteName,
    this.description,
    this.imageUrl,
    this.faviconUrl,
  });

  final String? siteName;
  final String? description;
  final String? imageUrl;
  final String? faviconUrl;

  Map<String, dynamic> toJson() => {
        'siteName': siteName,
        'description': description,
        'imageUrl': imageUrl,
        'faviconUrl': faviconUrl,
      };

  bool isEmpty() {
    return siteName == null ||
        description == null ||
        imageUrl == null ||
        faviconUrl == null;
  }

  Widget buildIconWidget({Size size = const Size.square(20.0)}) {
    final iconUrl = faviconUrl;
    if (iconUrl == null) {
      return FlowySvg(FlowySvgs.toolbar_link_earth_m, size: size);
    }
    if (iconUrl.endsWith('.svg')) {
      return FlowyNetworkSvg(
        iconUrl,
        height: size.height,
        width: size.width,
        errorWidget: const FlowySvg(FlowySvgs.toolbar_link_earth_m),
      );
    }
    return FlowyNetworkImage(
      url: iconUrl,
      fit: BoxFit.contain,
      height: size.height,
      width: size.width,
      errorWidgetBuilder: (context, error, stackTrace) =>
          const FlowySvg(FlowySvgs.toolbar_link_earth_m),
    );
  }
}

class LinkInfoCache {
  final _linkInfoPrefix = 'link_info';

  Future<LinkInfo?> get(String url) async {
    final option = await getIt<KeyValueStorage>().getWithFormat<LinkInfo?>(
      _linkInfoPrefix + url,
      (value) => LinkInfo.fromJson(jsonDecode(value)),
    );
    return option;
  }

  Future<void> set(String url, LinkInfo data) async {
    await getIt<KeyValueStorage>().set(
      _linkInfoPrefix + url,
      jsonEncode(data.toJson()),
    );
  }
}

enum LinkLoadingStatus {
  loading,
  idle,
  error,
}
