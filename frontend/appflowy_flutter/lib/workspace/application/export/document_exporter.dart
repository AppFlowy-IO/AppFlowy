import 'dart:convert';

import 'package:appflowy/generated/locale_keys.g.dart';
import 'package:appflowy/plugins/document/application/document_data_pb_extension.dart';
import 'package:appflowy/plugins/document/application/prelude.dart';
import 'package:appflowy/plugins/document/presentation/editor_plugins/parsers/document_markdown_parsers.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_result/appflowy_result.dart';
import 'package:easy_localization/easy_localization.dart';

const List<NodeParser> _customParsers = [
  MathEquationNodeParser(),
  CalloutNodeParser(),
  ToggleListNodeParser(),
  CustomImageNodeParser(),
];

enum DocumentExportType {
  json,
  markdown,
  text,
  html,
}

class DocumentExporter {
  const DocumentExporter(
    this.view,
  );

  final ViewPB view;

  Future<FlowyResult<String, FlowyError>> export(
    DocumentExportType type,
  ) async {
    final documentService = DocumentService();
    final result = await documentService.openDocument(documentId: view.id);
    return result.fold(
      (r) {
        final document = r.toDocument();
        if (document == null) {
          return FlowyResult.failure(
            FlowyError(
              msg: LocaleKeys.settings_files_exportFileFail.tr(),
            ),
          );
        }
        switch (type) {
          case DocumentExportType.json:
            return FlowyResult.success(jsonEncode(document));
          case DocumentExportType.markdown:
            final markdown = documentToMarkdown(
              document,
              customParsers: _customParsers,
            );
            return FlowyResult.success(markdown);
          case DocumentExportType.text:
            throw UnimplementedError();
          case DocumentExportType.html:
            final html = documentToHTML(
              document,
            );
            return FlowyResult.success(html);
        }
      },
      (error) => FlowyResult.failure(error),
    );
  }
}
