import 'dart:convert';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/link_preview_node_parser.dart';
import 'package:appflowy/shared/markdown_to_document.dart';
import 'package:appflowy/workspace/application/export/document_link_resolver.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';

enum DocumentExportType { json, markdown, text, html }

/// Converts a [Document] into an HTML string, resolving links (mentions, bookmarks, embeds)
/// into standard anchors while filtering unsafe URL schemes.
String exportDocumentToHTML(Document document) {
  final resolvedDocument = resolveDocumentLinksForExport(document);
  return documentToHTML(
    resolvedDocument,
    customParsers: [const HTMLLinkPreviewNodeParser()],
  );
}

class DocumentExporter {
  const DocumentExporter(this.view);

  final ViewPB view;

  Future<FlowyResult<String, FlowyError>> export(
    DocumentExportType type, {
    String? path,
  }) async {
    final documentService = DocumentService();
    final result = await documentService.openDocument(documentId: view.id);
    return result.fold((r) async {
      final document = r.toDocument();
      if (document == null) {
        return FlowyResult.failure(
          FlowyError(msg: LocaleKeys.settings_files_exportFileFail.tr()),
        );
      }
      switch (type) {
        case DocumentExportType.json:
          return FlowyResult.success(jsonEncode(document));
        case DocumentExportType.markdown:
          if (path != null) {
            await customDocumentToMarkdown(document, path: path);
            return FlowyResult.success('');
          } else {
            return FlowyResult.success(
              await customDocumentToMarkdown(document),
            );
          }
        case DocumentExportType.text:
          throw UnimplementedError();
        case DocumentExportType.html:
          return FlowyResult.success(exportDocumentToHTML(document));
      }
    }, (error) => FlowyResult.failure(error));
  }
}
