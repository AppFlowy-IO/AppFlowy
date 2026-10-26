import 'package:appflowy/workspace/application/export/document_link_resolver.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:html/dom.dart' as dom;

class LinkPreviewNodeParser extends NodeParser {
  const LinkPreviewNodeParser();

  @override
  String get id => LinkPreviewBlockKeys.type;

  @override
  String transform(Node node, DocumentMarkdownEncoder? encoder) {
    final href = node.attributes[LinkPreviewBlockKeys.url];
    if (href == null) {
      return '';
    }
    final url = href.toString();
    if (!isSafeExportUrl(url)) {
      return '$url\n';
    }
    return '[$url]($url)\n';
  }
}

class HTMLLinkPreviewNodeParser extends HTMLNodeParser {
  const HTMLLinkPreviewNodeParser();

  @override
  String get id => LinkPreviewBlockKeys.type;

  @override
  String transformNodeToHTMLString(
    Node node, {
    required List<HTMLNodeParser> encodeParsers,
  }) {
    return toHTMLString(
      transformNodeToDomNodes(node, encodeParsers: encodeParsers),
    );
  }

  @override
  List<dom.Node> transformNodeToDomNodes(
    Node node, {
    required List<HTMLNodeParser> encodeParsers,
  }) {
    final href = node.attributes[LinkPreviewBlockKeys.url];
    if (href == null || (href is String && href.isEmpty)) {
      return [];
    }
    final url = href.toString();
    if (!isSafeExportUrl(url)) {
      final paragraph = dom.Element.tag(HTMLTags.paragraph)
        ..append(dom.Text(url));
      return [paragraph];
    }
    final anchor = dom.Element.tag(HTMLTags.anchor)
      ..attributes['href'] = url
      ..append(dom.Text(url));
    final paragraph = dom.Element.tag(HTMLTags.paragraph)..append(anchor);
    return [paragraph];
  }
}
