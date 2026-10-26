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
          final resolvedDocument = resolveDocumentLinksForExport(document);
          if (path != null) {
            await customDocumentToMarkdown(resolvedDocument, path: path);
            return FlowyResult.success('');
          } else {
            return FlowyResult.success(
              await customDocumentToMarkdown(resolvedDocument),
            );
          }
        case DocumentExportType.text:
          throw UnimplementedError();
        case DocumentExportType.html:
          final resolvedDocument = resolveDocumentLinksForExport(document);
          final html = documentToHTML(
            resolvedDocument,
            customParsers: [const HTMLLinkPreviewNodeParser()],
          );
          return FlowyResult.success(html);
      }
    }, (error) => FlowyResult.failure(error));
  }
}
