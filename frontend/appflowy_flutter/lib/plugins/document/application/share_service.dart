import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:appflowy_backend/dispatch/dispatch.dart';
import 'package:appflowy_backend/protobuf/flowy-error/errors.pb.dart';
import 'package:appflowy_backend/protobuf/flowy-document/protobuf.dart';
import 'package:appflowy_backend/protobuf/flowy-folder/view.pb.dart';

class ShareService {
  Future<Either<ExportDataPB, FlowyError>> export(
    final ViewPB view,
    final ExportType type,
  ) {
    final payload = ExportPayloadPB.create()
      ..viewId = view.id
      ..exportType = type
      ..documentVersion = DocumentVersionPB.V1;

    return DocumentEventExportDocument(payload).send();
  }

  Future<Either<ExportDataPB, FlowyError>> exportText(final ViewPB view) {
    return export(view, ExportType.Text);
  }

  Future<Either<ExportDataPB, FlowyError>> exportMarkdown(final ViewPB view) {
    return export(view, ExportType.Markdown);
  }

  Future<Either<ExportDataPB, FlowyError>> exportURL(final ViewPB view) {
    return export(view, ExportType.Link);
  }
}
