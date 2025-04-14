import 'package:appflowy/plugins/document/presentation/editor_plugins/link_preview/custom_link_parser.dart';
import 'package:appflowy_backend/log.dart';

import 'package:http/http.dart' as http;
// ignore: depend_on_referenced_packages
import 'package:html/parser.dart' as html_parser;

abstract class LinkInfoParser {
  Future<LinkInfo?> parse(
    Uri link, {
    Duration timeout = const Duration(seconds: 8),
    Map<String, String>? headers,
  });

  static String formatUrl(String url) {
    Uri? uri = Uri.tryParse(url);
    if (uri == null) return url;
    if (!uri.hasScheme) uri = Uri.tryParse('http://$url');
    if (uri == null) return url;
    final isHome = (uri.hasEmptyPath || uri.path == '/') && !uri.hasQuery;
    final homeUrl = '${uri.scheme}://${uri.host}/';
    if (isHome) return homeUrl;
    return '$uri';
  }
}

class DefaultParser implements LinkInfoParser {
  @override
  Future<LinkInfo?> parse(
    Uri link, {
    Duration timeout = const Duration(seconds: 8),
    Map<String, String>? headers,
  }) async {
    try {
      final isHome = (link.hasEmptyPath || link.path == '/') && !link.hasQuery;
      final http.Response response =
          await http.get(link, headers: headers).timeout(timeout);
      final code = response.statusCode;
      if (code != 200 && isHome) {
        throw Exception('Http request error: $code');
      }
      //  else if (!isHome && code == 403) {
      //   uri = Uri.parse('${uri.scheme}://${uri.host}/');
      //   response = await http.get(uri).timeout(timeout);
      // }

      final document = html_parser.parse(response.body);

      final siteName = document
          .querySelector('meta[property="og:site_name"]')
          ?.attributes['content'];

      String? title = document
          .querySelector('meta[property="og:title"]')
          ?.attributes['content'];
      title ??= document.querySelector('title')?.text;

      String? description = document
          .querySelector('meta[property="og:description"]')
          ?.attributes['content'];
      description ??= document
          .querySelector('meta[name="description"]')
          ?.attributes['content'];

      String? imageUrl = document
          .querySelector('meta[property="og:image"]')
          ?.attributes['content'];
      if (imageUrl != null && !imageUrl.startsWith('http')) {
        imageUrl = link.resolve(imageUrl).toString();
      }

      final favicon =
          'https://www.google.com/s2/favicons?sz=64&domain=${link.host}';

      return LinkInfo(
        url: '$link',
        siteName: siteName,
        title: title,
        description: description,
        imageUrl: imageUrl,
        faviconUrl: favicon,
      );
    } catch (e) {
      Log.error('Parse link $link error: $e');
      return null;
    }
  }
}
