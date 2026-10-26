import 'package:appflowy/shared/mention_block_keys.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor_plugins/appflowy_editor_plugins.dart';
import 'package:easy_localization/easy_localization.dart';

const safeExportUrlSchemes = {'http', 'https', 'mailto', 'ftp'};

/// Validates whether a given URL uses a safe scheme for export as a clickable link.
///
/// Unsafe schemes (such as `javascript:`, `vbscript:`, `data:`) must not be rendered
/// as active links in exported HTML or pasted content.
bool isSafeExportUrl(String? url) {
  if (url == null || url.trim().isEmpty) return false;
  final trimmed = url.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return false;
  if (uri.hasScheme) {
    return safeExportUrlSchemes.contains(uri.scheme.toLowerCase());
  }
  final colonIndex = trimmed.indexOf(':');
  if (colonIndex != -1) {
    final slashIndex = trimmed.indexOf('/');
    if (slashIndex == -1 || colonIndex < slashIndex) {
      final scheme = trimmed.substring(0, colonIndex).toLowerCase();
      return safeExportUrlSchemes.contains(scheme);
    }
  }
  return true;
}

/// Converts special link elements (mentions with external links, URL bookmarks,
/// and embeds) within a [Document] into standard link representations
/// expected by downstream exporters (Markdown, HTML, clipboard).
///
/// Preserves the original document root node ID, type, and attributes so that
/// downstream export archive and resource paths remain stable and deterministic.
Document resolveDocumentLinksForExport(Document document) {
  final resolvedChildren = document.root.children
      .map(_resolveNodeForExport)
      .toList();
  return Document(root: document.root.copyWith(children: resolvedChildren));
}

Node _resolveNodeForExport(Node node) {
  final resolvedChildren = node.children.map(_resolveNodeForExport).toList();

  // Convert Bookmark / Embed block node to paragraph with standard link
  if (node.type == LinkPreviewBlockKeys.type) {
    final url = node.attributes[LinkPreviewBlockKeys.url] as String?;
    if (url != null && url.isNotEmpty) {
      if (isSafeExportUrl(url)) {
        return paragraphNode(
          delta: Delta()
            ..insert(url, attributes: {AppFlowyRichTextKeys.href: url}),
          children: resolvedChildren,
        );
      } else {
        return paragraphNode(
          delta: Delta()..insert(url),
          children: resolvedChildren,
        );
      }
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
          ..insert(
            url,
            attributes: isSafeExportUrl(url)
                ? {AppFlowyRichTextKeys.href: url}
                : null,
          );
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

        // 1. External link mention -> convert to standard link with URL as text if safe
        final url = mention[MentionBlockKeys.url] as String?;
        if (url != null && url.isNotEmpty) {
          if (isSafeExportUrl(url)) {
            newDelta.insert(
              url,
              attributes: {
                ...remainingAttributes,
                AppFlowyRichTextKeys.href: url,
              },
            );
          } else {
            newDelta.insert(
              url,
              attributes: remainingAttributes.isNotEmpty
                  ? remainingAttributes
                  : null,
            );
          }
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
