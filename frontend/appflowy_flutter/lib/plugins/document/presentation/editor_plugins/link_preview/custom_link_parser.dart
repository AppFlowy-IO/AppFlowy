import 'dart:convert';
import 'package:appflowy/core/config/kv.dart';
import 'package:appflowy/generated/flowy_svgs.g.dart';
import 'package:appflowy/shared/appflowy_network_image.dart';
import 'package:appflowy/shared/appflowy_network_svg.dart';
import 'package:appflowy/startup/startup.dart';
import 'package:appflowy_backend/log.dart';
import 'package:flutter/material.dart';
import 'link_parsers/default_parser.dart';
import 'link_parsers/youtube_parser.dart';

class LinkParser {
  final Set<ValueChanged<LinkInfo>> _listeners = <ValueChanged<LinkInfo>>{};
  static final Map<String, LinkInfoParser> _hostToParsers = {
    'www.youtube.com': YoutubeParser(),
    'youtube.com': YoutubeParser(),
  };

  Future<void> start(String url, {LinkInfoParser? parser}) async {
    final uri = Uri.tryParse(LinkInfoParser.formatUrl(url)) ?? Uri.parse(url);
    final data = await LinkInfoCache.get(uri);
    if (data != null) {
      refreshLinkInfo(data);
    }

    final host = uri.host;
    final currentParser = parser ?? _hostToParsers[host] ?? DefaultParser();
    await _getLinkInfo(uri, currentParser);
  }

  Future<LinkInfo?> _getLinkInfo(Uri uri, LinkInfoParser parser) async {
    try {
      final linkInfo = await parser.parse(uri) ?? LinkInfo(url: '$uri');
      if (!linkInfo.isEmpty()) await LinkInfoCache.set(uri, linkInfo);
      refreshLinkInfo(linkInfo);
      return linkInfo;
    } catch (e, s) {
      Log.error('get link info error: ', e, s);
      refreshLinkInfo(LinkInfo(url: '$uri'));
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
        url: json['url'] ?? '',
        title: json['title'],
        description: json['description'],
        imageUrl: json['imageUrl'],
        faviconUrl: json['faviconUrl'],
      );

  LinkInfo({
    required this.url,
    this.siteName,
    this.title,
    this.description,
    this.imageUrl,
    this.faviconUrl,
  });

  final String url;
  final String? siteName;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? faviconUrl;

  Map<String, dynamic> toJson() => {
        'url': url,
        'siteName': siteName,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'faviconUrl': faviconUrl,
      };

  @override
  String toString() {
    return 'LinkInfo{url: $url, siteName: $siteName, title: $title, description: $description, imageUrl: $imageUrl, faviconUrl: $faviconUrl}';
  }

  bool isEmpty() {
    return title == null;
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
  static const _linkInfoPrefix = 'link_info';

  static Future<LinkInfo?> get(Uri uri) async {
    final option = await getIt<KeyValueStorage>().getWithFormat<LinkInfo?>(
      '$_linkInfoPrefix$uri',
      (value) => LinkInfo.fromJson(jsonDecode(value)),
    );
    return option;
  }

  static Future<void> set(Uri uri, LinkInfo data) async {
    await getIt<KeyValueStorage>().set(
      '$_linkInfoPrefix$uri',
      jsonEncode(data.toJson()),
    );
  }
}

enum LinkLoadingStatus {
  loading,
  idle,
  error,
}
