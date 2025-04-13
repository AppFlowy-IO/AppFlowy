import 'dart:convert';

import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/custom_link_parser.dart';
import 'package:appflowy_backend/log.dart';
import 'package:http/http.dart' as http;
import 'default_parser.dart';

class YoutubeParser implements LinkInfoParser {
  @override
  Future<LinkInfo?> parse(
    Uri link, {
    Duration timeout = const Duration(seconds: 8),
    Map<String, String>? headers,
  }) async {
    try {
      final isHome = (link.hasEmptyPath || link.path == '/') && !link.hasQuery;
      if (isHome) {
        return DefaultParser().parse(
          link,
          timeout: timeout,
          headers: headers,
        );
      }

      final requestLink =
          'https://www.youtube.com/oembed?url=$link&format=json';
      final http.Response response = await http
          .get(Uri.parse(requestLink), headers: headers)
          .timeout(timeout);
      final code = response.statusCode;
      if (code != 200) {
        throw Exception('Http request error: $code');
      }

      final youtubeInfo = YoutubeInfo.fromJson(jsonDecode(response.body));

      final favicon =
          'https://www.google.com/s2/favicons?sz=64&domain=${link.host}';
      return LinkInfo(
        url: '$link',
        title: youtubeInfo.title,
        siteName: youtubeInfo.authorName,
        imageUrl: youtubeInfo.thumbnailUrl,
        faviconUrl: favicon,
      );
    } catch (e) {
      Log.error('Parse link $link error: $e');
      return null;
    }
  }
}

class YoutubeInfo {
  YoutubeInfo({
    this.title,
    this.authorName,
    this.version,
    this.providerName,
    this.providerUrl,
    this.thumbnailUrl,
  });

  YoutubeInfo.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    authorName = json['author_name'];
    version = json['version'];
    providerName = json['provider_name'];
    providerUrl = json['provider_url'];
    thumbnailUrl = json['thumbnail_url'];
  }
  String? title;
  String? authorName;
  String? version;
  String? providerName;
  String? providerUrl;
  String? thumbnailUrl;

  Map<String, dynamic> toJson() => {
        'title': title,
        'author_name': authorName,
        'version': version,
        'provider_name': providerName,
        'provider_url': providerUrl,
        'thumbnail_url': thumbnailUrl,
      };
}
