import 'package:appflowy/plugins/document/presentation/editor_plugins/mention/mention_block.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';

/// Converts special link elements (mentions with external links, URL bookmarks,
/// and embeds) within a [Document] into standard link representations
/// expected by downstream exporters (Markdown, HTML, clipboard).
Document resolveDocumentLinksForExport(Document document) {
  final newDocument = Document.blank();
  final resolvedChildren = document.root.children
      .map(_resolveNodeForExport)
      .toList();
  newDocument.insert([0], resolvedChildren);
  return newDocument;
}

Node _resolveNodeForExport(Node node) {
  final resolvedChildren = node.children.map(_resolveNodeForExport).toList();

  // Convert Bookmark / Embed block node to paragraph with standard link
  if (node.type == LinkPreviewBlockKeys.type) {
    final url = node.attributes[LinkPreviewBlockKeys.url] as String?;
    if (url != null && url.isNotEmpty) {
      return paragraphNode(
        delta: Delta()
          ..insert(url, attributes: {AppFlowyRichTextKeys.href: url}),
        children: resolvedChildren,
      );
    }
  }

  final delta = node.delta;
  if (delta != null) {
    var resolvedDelta = resolveDeltaForExport(delta);

    // If node is a checkbox or container that had link_preview attributes but empty delta
    if (resolvedDelta.isEmpty) {
      final url = node.attributes[LinkPreviewBlockKeys.url] as String?;
      if (url != null && url.isNotEmpty) {
        resolvedDelta = Delta()
          ..insert(url, attributes: {AppFlowyRichTextKeys.href: url});
      }
    }

    return node.copyWith(
      attributes: {...node.attributes, 'delta': resolvedDelta.toJson()},
      children: resolvedChildren,
    );
  }

  return node.copyWith(children: resolvedChildren);
}

/// Converts mentions within a [Delta] into their corresponding link or text
/// representations so downstream text/markdown/html encoders preserve URLs.
Delta resolveDeltaForExport(Delta delta) {
  final newDelta = Delta();
  for (final op in delta) {
    if (op is TextInsert) {
      final attributes = op.attributes;
      final mention = attributes?[MentionBlockKeys.mention];
      if (mention is Map) {
        final remainingAttributes = Map<String, dynamic>.from(attributes!)
          ..remove(MentionBlockKeys.mention);

        // 1. External link mention -> convert to standard link with URL as text
        final url = mention[MentionBlockKeys.url] as String?;
        if (url != null && url.isNotEmpty) {
          newDelta.insert(
            url,
            attributes: {
              ...remainingAttributes,
              AppFlowyRichTextKeys.href: url,
            },
          );
          continue;
        }

        // 2. Date mention -> convert to formatted date text
        final date = mention[MentionBlockKeys.date] as String?;
        if (date != null && date.isNotEmpty) {
          final dateTime = DateTime.tryParse(date);
          if (dateTime != null) {
            newDelta.insert(
              DateFormat.yMMMd().format(dateTime),
              attributes: remainingAttributes.isNotEmpty
                  ? remainingAttributes
                  : null,
            );
            continue;
          }
        }

        // 3. Page mention -> convert to link with empty text []($pageId)
        final pageId = mention[MentionBlockKeys.pageId] as String?;
        if (pageId != null && pageId.isNotEmpty) {
          newDelta.insert(
            '',
            attributes: {
              ...remainingAttributes,
              AppFlowyRichTextKeys.href: pageId,
            },
          );
          continue;
        }
      }
      newDelta.add(op);
    } else {
      newDelta.add(op);
    }
  }
  return newDelta;
}
